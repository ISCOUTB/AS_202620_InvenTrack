import pytest
import asyncio
from app.messaging.broker_simulador import SimuladorBrokerMensajeria, DeadLetterQueue


@pytest.mark.asyncio
async def test_procesamiento_exitoso_y_trazabilidad():
    """Verifica que un mensaje válido se procese correctamente con Correlation ID y traza de auditoría."""
    broker = SimuladorBrokerMensajeria()
    procesados = []

    async def consumidor_simulado(msg):
        procesados.append(msg)

    mensaje = {
        "event_id": "111e8400-e29b-41d4-a716-446655440000",
        "correlation_id": "corr-xyz-123",
        "idempotency_key": "key-001",
        "timestamp": "2026-10-26T00:00:00Z",
        "data": {"producto_id": "SKU-001", "cantidad": 5, "tipo": "ENTRADA", "stock_final": 15}
    }

    resultado = await broker.publicar("inventario.movimientos", mensaje, consumidor_simulado)
    
    assert resultado is True
    assert len(procesados) == 1
    assert broker.audit_log[-1]["status"] == "PROCESSED_SUCCESS"
    assert broker.audit_log[-1]["correlation_id"] == "corr-xyz-123"


@pytest.mark.asyncio
async def test_idempotencia_y_deduplicacion():
    """Verifica que un mensaje duplicado (misma idempotency_key) sea omitido y no reprocesado (Punto 3 del Taller)."""
    broker = SimuladorBrokerMensajeria()
    contador = 0

    async def consumidor_simulado(msg):
        nonlocal contador
        contador += 1

    mensaje = {
        "event_id": "222e8400-e29b-41d4-a716-446655440000",
        "correlation_id": "corr-xyz-456",
        "idempotency_key": "key-duplicada",
        "timestamp": "2026-10-26T00:00:00Z",
        "data": {"producto_id": "SKU-002", "cantidad": 2, "tipo": "SALIDA", "stock_final": 8}
    }

    # Primera publicación (debe procesarse)
    res1 = await broker.publicar("inventario.movimientos", mensaje, consumidor_simulado)
    # Segunda publicación duplicada (debe ser interceptada por idempotencia)
    res2 = await broker.publicar("inventario.movimientos", mensaje, consumidor_simulado)

    assert res1 is True
    assert res2 is True
    assert contador == 1  # El consumidor solo se ejecutó una vez
    assert broker.audit_log[-1]["status"] == "DUPLICATE_SKIPPED"


@pytest.mark.asyncio
async def test_fallo_recuperable_con_reintentos_y_exito():
    """Verifica el comportamiento ante fallos temporales: reintento con backoff y éxito posterior."""
    broker = SimuladorBrokerMensajeria(max_retries=3, base_backoff=0.01)
    intentos = 0

    async def consumidor_fallo_temporal(msg):
        nonlocal intentos
        intentos += 1
        if intentos < 3:
            raise ConnectionError("Fallo temporal de red simulado")
        return True

    mensaje = {
        "event_id": "333e8400-e29b-41d4-a716-446655440000",
        "correlation_id": "corr-retry-789",
        "idempotency_key": "key-retry",
        "timestamp": "2026-10-26T00:00:00Z",
        "data": {"producto_id": "SKU-003", "cantidad": 1, "tipo": "ENTRADA", "stock_final": 10}
    }

    resultado = await broker.publicar("inventario.movimientos", mensaje, consumidor_fallo_temporal)

    assert resultado is True
    assert intentos == 3
    assert broker.dlq.size() == 0
    assert broker.audit_log[-1]["status"] == "PROCESSED_SUCCESS"


@pytest.mark.asyncio
async def test_fallo_persistente_envia_a_dlq():
    """Verifica que si se agotan los reintentos, el mensaje sea enviado a la Dead Letter Queue (DLQ)."""
    broker = SimuladorBrokerMensajeria(max_retries=2, base_backoff=0.01)

    async def consumidor_roto(msg):
        raise RuntimeError("Fallo crítico irrecuperable en base de datos")

    mensaje = {
        "event_id": "444e8400-e29b-41d4-a716-446655440000",
        "correlation_id": "corr-dlq-999",
        "idempotency_key": "key-dlq",
        "timestamp": "2026-10-26T00:00:00Z",
        "data": {"producto_id": "SKU-004", "cantidad": 3, "tipo": "SALIDA", "stock_final": 2}
    }

    resultado = await broker.publicar("inventario.movimientos", mensaje, consumidor_roto)

    assert resultado is False
    assert broker.dlq.size() == 1
    assert broker.audit_log[-1]["status"] == "SENT_TO_DLQ"
    assert "Fallo crítico irrecuperable" in broker.dlq.messages[0]["error"]