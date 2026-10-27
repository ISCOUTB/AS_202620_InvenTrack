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
        self.published_messages: List[Dict[str, Any]] = []
        self.metrics: Dict[str, int] = {
            "published": 0,
            "processed": 0,
            "duplicates": 0,
            "retries": 0,
            "dlq": 0,
        }
        self._deduplication_lock = asyncio.Lock()
        self._in_flight_keys: set[str] = set()

    async def publicar(self, message: Dict[str, Any], consumidor: Callable[[Dict[str, Any]], Any]) -> bool:
        """
        Publica un mensaje garantizando entrega At-Least-Once, manejo de reintentos
        con backoff exponencial, deduplicación y derivación a DLQ.
        """
        event_id = message.get("event_id")
        correlation_id = message.get("correlation_id", "N/A")
        idempotency_key = message.get("idempotency_key", event_id)
        self.published_messages.append(message)
        self.metrics["published"] += 1

        if await self._es_duplicado(
            idempotency_key, event_id, correlation_id
        ):
            return True  # Se considera procesado con éxito (idempotente)

        return await self._procesar_con_reintentos(
            message, consumidor, event_id, correlation_id, idempotency_key
        )

    async def _es_duplicado(
        self, idempotency_key: str, event_id: Any, correlation_id: str
    ) -> bool:
        """Reserva la clave y registra los mensajes que ya están en proceso o procesados."""
        async with self._deduplication_lock:
            if idempotency_key not in self.processed_events and idempotency_key not in self._in_flight_keys:
                self._in_flight_keys.add(idempotency_key)
                return False
            self.metrics["duplicates"] += 1

        logger.warning(
            f"[Idempotencia] Mensaje duplicado detectado y omitido. "
            f"Event ID: {event_id}, Key: {idempotency_key}"
        )
        self.audit_log.append({
            "event_id": event_id,
            "correlation_id": correlation_id,
            "status": "DUPLICATE_SKIPPED",
            "timestamp": datetime.now(timezone.utc).isoformat()
        })
        return True

    async def _procesar_con_reintentos(
        self,
        message: Dict[str, Any],
        consumidor: Callable[[Dict[str, Any]], Any],
        event_id: Any,
        correlation_id: str,
        idempotency_key: str,
    ) -> bool:
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
                async with self._deduplication_lock:
                    self._in_flight_keys.discard(idempotency_key)
                    self.processed_events.add(idempotency_key)
                self.metrics["processed"] += 1
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
                if intentos < self.max_retries:
                    self.metrics["retries"] += 1
                logger.warning(f"[Fallo Recuperable] Error procesando {event_id} en intento {intentos}: {ultimo_error}")
                
                if intentos < self.max_retries:
                    # Exponential Backoff: base * (2 ^ (intentos - 1))
                    backoff_time = self.base_backoff * (2 ** (intentos - 1))
                    await asyncio.sleep(backoff_time)

        async with self._deduplication_lock:
            self._in_flight_keys.discard(idempotency_key)
        self.dlq.push(message, ultimo_error)
        self.metrics["dlq"] += 1
        self.audit_log.append({
            "event_id": event_id,
            "correlation_id": correlation_id,
            "status": "SENT_TO_DLQ",
            "error": ultimo_error,
            "timestamp": datetime.now(timezone.utc).isoformat()
        })
        return False