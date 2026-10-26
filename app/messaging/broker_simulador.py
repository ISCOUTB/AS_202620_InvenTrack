import asyncio
import logging
from typing import Any, Callable, Dict, List, Optional
from datetime import datetime, timezone

logger = logging.getLogger("InvenTrack.Messaging")
logger.setLevel(logging.INFO)


class DeadLetterQueue:
    """Cola de Mensajes Fallidos (DLQ) para almacenar mensajes que agotaron los reintentos."""
    def __init__(self) -> None:
        self.messages: List[Dict[str, Any]] = []

    def push(self, message: Dict[str, Any], error: str) -> None:
        dlq_entry = {
            "message": message,
            "error": error,
            "failed_at": datetime.now(timezone.utc).isoformat()
        }
        self.messages.append(dlq_entry)
        logger.error(f"[DLQ] Mensaje enviado a DLQ por fallo persistente: {message.get('event_id')} | Error: {error}")

    def size(self) -> int:
        return len(self.messages)

    def clear(self) -> None:
        self.messages.clear()


class SimuladorBrokerMensajeria:
    """
    Simulador robusto de un broker de mensajes asíncrono con:
    - Garantía de entrega At-Least-Once
    - Política de reintentos con Exponential Backoff
    - Dead Letter Queue (DLQ) para fallos irrecuperables
    - Deduplicación por Clave de Idempotencia / Event ID
    """
    def __init__(self, max_retries: int = 3, base_backoff: float = 0.05) -> None:
        self.max_retries = max_retries
        self.base_backoff = base_backoff
        self.dlq = DeadLetterQueue()
        self.processed_events: set = set()  # Set para deduplicación (Idempotencia)
        self.audit_log: List[Dict[str, Any]] = []

    async def publicar(self, topic: str, message: Dict[str, Any], consumidor: Callable[[Dict[str, Any]], Any]) -> bool:
        """
        Publica un mensaje garantizando entrega At-Least-Once, manejo de reintentos
        con backoff exponencial, deduplicación y derivación a DLQ.
        """
        event_id = message.get("event_id")
        correlation_id = message.get("correlation_id", "N/A")
        idempotency_key = message.get("idempotency_key", event_id)

        # 1. Verificación de Idempotencia / Deduplicación (Punto 3 del Taller)
        if idempotency_key in self.processed_events:
            logger.warning(f"[Idempotencia] Mensaje duplicado detectado y omitido. Event ID: {event_id}, Key: {idempotency_key}")
            self.audit_log.append({
                "event_id": event_id,
                "correlation_id": correlation_id,
                "status": "DUPLICATE_SKIPPED",
                "timestamp": datetime.now(timezone.utc).isoformat()
            })
            return True  # Se considera procesado con éxito (idempotente)

        # 2. Ciclo de reintentos con Exponential Backoff (Punto 4 del Taller)
        intentos = 0
        ultimo_error = ""

        while intentos < self.max_retries:
            try:
                logger.info(f"[Productor -> Consumidor] [CorrID: {correlation_id}] Intentando procesar evento {event_id} (Intento {intentos + 1}/{self.max_retries})")
                
                # Ejecución de la lógica del consumidor
                if asyncio.iscoroutinefunction(consumidor):
                    await consumidor(message)
                else:
                    consumidor(message)

                # Éxito: Marcar como procesado para futuras deduplicaciones
                self.processed_events.add(idempotency_key)
                self.audit_log.append({
                    "event_id": event_id,
                    "correlation_id": correlation_id,
                    "status": "PROCESSED_SUCCESS",
                    "attempts": intentos + 1,
                    "timestamp": datetime.now(timezone.utc).isoformat()
                })
                logger.info(f"[Éxito] Mensaje {event_id} procesado correctamente.")
                return True

            except Exception as e:
                intentos += 1
                ultimo_error = str(e)
                logger.warning(f"[Fallo Recuperable] Error procesando {event_id} en intento {intentos}: {ultimo_error}")
                
                if intentos < self.max_retries:
                    # Exponential Backoff: base * (2 ^ (intentos - 1))
                    backoff_time = self.base_backoff * (2 ** (intentos - 1))
                    await asyncio.sleep(backoff_time)

        # 3. Si se agotan los reintentos, va a la Dead Letter Queue (DLQ)
        self.dlq.push(message, ultimo_error)
        self.audit_log.append({
            "event_id": event_id,
            "correlation_id": correlation_id,
            "status": "SENT_TO_DLQ",
            "error": ultimo_error,
            "timestamp": datetime.now(timezone.utc).isoformat()
        })
        return False