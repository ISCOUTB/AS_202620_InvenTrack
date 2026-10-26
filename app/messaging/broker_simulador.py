@pytest.mark.asyncio
async def test_consumidor_sincrono_fallback_idempotencia_y_dlq_utils():
    """Verifica un consumidor síncrono, el fallback de idempotency_key y las utilidades de size/clear de la DLQ."""
    broker = SimuladorBrokerMensajeria()
    procesados = []

    # Consumidor síncrono (no corrutina async)
    def consumidor_sincrono(msg):
        procesados.append(msg)

    mensaje = {
        "event_id": "555e8400-e29b-41d4-a716-446655440000",
        "correlation_id": "corr-sync-111",
        # Omitimos 'idempotency_key' intencionalmente para probar el fallback a event_id
        "timestamp": "2026-10-26T00:00:00Z",
        "data": {"producto_id": "SKU-005", "cantidad": 4, "tipo": "ENTRADA", "stock_final": 19}
    }

    resultado = await broker.publicar("inventario.movimientos", mensaje, consumidor_sincrono)
    assert resultado is True
    assert len(procesados) == 1

    # Cubrir métodos size() y clear() de la Dead Letter Queue explícitamente
    broker.dlq.push(mensaje, "Error de prueba para DLQ utils")
    assert broker.dlq.size() == 1
    broker.dlq.clear()
    assert broker.dlq.size() == 0