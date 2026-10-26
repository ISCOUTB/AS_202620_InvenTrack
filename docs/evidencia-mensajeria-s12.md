# Evidencia del taller de mensajería

## Alcance

La operación real seleccionada es el registro de entradas y salidas de
inventario. El stock se confirma síncronamente; la auditoría se publica como
evento en segundo plano. La implementación es un simulador local en memoria,
no un broker durable.

## Reproducción

Desde la raíz del repositorio, con las dependencias instaladas:

```powershell
$env:PYTHONPATH='.'
pytest -q tests\messaging\test_taller_mensajeria.py tests\messaging\test_contrato_evento.py tests\inventario\test_inventario.py tests\contract\test_openapi_contract.py
```

La ejecución cubre procesamiento correcto, correlación, duplicados, fallos
recuperables, backoff, DLQ, publicación desde una entrada real, contrato JSON
Schema y contrato OpenAPI.

Resultado observado:

```text
15 passed, 1 warning
```

La advertencia corresponde a `pytest-asyncio` y no afecta las pruebas. En una
ejecución real de una entrada con `X-Correlation-ID: corr-evidencia` y
`X-Idempotency-Key: cmd-evidencia`, los logs observados fueron:

```text
[Productor -> Consumidor] [CorrID: corr-evidencia] Intentando procesar evento ... (Intento 1/3)
inventory_message_consumed ... "correlation_id": "corr-evidencia", "topic": "inventario.movimientos"
[Éxito] Mensaje ... procesado correctamente.
```

La respuesta de `/metrics` incluyó:

```text
inventrack_messaging_messages_total{status="published"} 1
inventrack_messaging_messages_total{status="processed"} 1
inventrack_messaging_messages_total{status="duplicates"} 0
inventrack_messaging_messages_total{status="retries"} 0
inventrack_messaging_messages_total{status="dlq"} 0
```

## Mapa de verificación

| Propiedad | Evidencia |
|---|---|
| Contrato y compatibilidad | `contracts/events/movimiento_registrado_v1.json`, `tests/messaging/test_contrato_evento.py`, ADR-0016 |
| Entrega | `app/messaging/broker_simulador.py`: At-Least-Once en proceso; límite de volatilidad documentado |
| Duplicados | `tests/messaging/test_taller_mensajeria.py::test_idempotencia_y_deduplicacion` |
| Duplicados concurrentes | `tests/messaging/test_taller_mensajeria.py::test_idempotencia_con_entregas_concurrentes` |
| Reintentos y backoff | `tests/messaging/test_taller_mensajeria.py::test_fallo_recuperable_con_reintentos_y_exito` |
| DLQ | `tests/messaging/test_taller_mensajeria.py::test_fallo_persistente_envia_a_dlq` |
| Flujo real | `tests/inventario/test_inventario.py::test_entrada_publica_evento_de_auditoria_con_trazabilidad` |
| Trazabilidad | `correlation_id`, `audit_log` y log `inventory_message_consumed` |

## Limitación aceptada

El simulador no sobrevive a un reinicio. La garantía declarada es At-Least-Once
durante la vida del proceso; para durabilidad se requiere un broker externo o
Outbox persistente, decisión fuera del alcance del MVP.
