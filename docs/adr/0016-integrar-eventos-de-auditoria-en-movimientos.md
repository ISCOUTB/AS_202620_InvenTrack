# ADR-0016: Integrar eventos de auditoría en movimientos de inventario

- **Estado:** Aceptado
- **Fecha:** 2026-10-25
- **Decisores:** Equipo InvenTrack
- **Reemplaza:** Ninguno; desarrolla la decisión de [ADR-0013](0013-evaluacion-mensajeria-asincrona-vs-sincrona.md)

## Contexto

El registro de entradas y salidas debe conservar consistencia inmediata del stock,
pero la auditoría es una tarea secundaria que puede ejecutarse después de la
respuesta HTTP. El taller exige demostrar desacoplamiento temporal, contrato,
entrega, duplicados, reintentos, DLQ y trazabilidad.

## Opciones evaluadas

1. **Invocación síncrona:** ejecutar la auditoría antes de responder. Es simple,
   pero aumenta la latencia y acopla temporalmente el registro de stock con el
   consumidor.
2. **Evento asíncrono en el proceso:** registrar stock de forma síncrona y
   publicar `MovimientoDeInventarioRegistrado` mediante `BackgroundTasks`.
   Mantiene consistencia local y permite reintentos y DLQ para la auditoría.
3. **Broker durable externo:** usar RabbitMQ o Kafka. Aporta durabilidad ante
   reinicios, pero introduce infraestructura y costo que no requiere el MVP.

## Decisión

Se adopta la opción 2. Las rutas reales de entradas y salidas crean el evento
después de una operación exitosa y lo entregan al simulador en segundo plano.
El consumidor de auditoría registra `event_id`, `correlation_id` y el tópico.
El simulador aplica entrega At-Least-Once durante la vida del proceso, reintentos
con backoff exponencial, deduplicación por `idempotency_key` y DLQ después de
agotar los reintentos.

La garantía no es durable: un reinicio puede perder mensajes y la DLQ porque
ambos son estructuras en memoria. Antes de escalar horizontalmente o exigir
recuperación ante reinicios se debe reemplazar el simulador por un broker durable
u Outbox persistente.

## Contrato y compatibilidad

El contrato es
[`contracts/events/movimiento_registrado_v1.json`](../../contracts/events/movimiento_registrado_v1.json).
Son obligatorios `event_id`, `correlation_id`, `idempotency_key`, `timestamp` y
`data`; dentro de `data` son obligatorios `producto_id`, `cantidad`, `tipo` y
`stock_final`.

Agregar propiedades opcionales sin cambiar la semántica es compatible. Cambiar
o eliminar campos obligatorios, tipos, valores permitidos o semántica requiere
una nueva versión del evento y coexistencia temporal de consumidores. El
contrato usa `additionalProperties: false`, por lo que un cambio no acordado
falla explícitamente en vez de ser aceptado silenciosamente.

## Consecuencias

- El stock conserva consistencia síncrona y el consumidor de auditoría queda
  desacoplado temporalmente.
- Los duplicados son esperables por At-Least-Once y se omiten mediante
  `idempotency_key`.
- Un fallo recuperable se reintenta con backoff; un fallo persistente termina en
  DLQ y queda visible en el registro de auditoría.
- La entrega y DLQ se pierden al reiniciar el proceso; es deuda técnica
  explícita, no una garantía de producción.

## Trazabilidad

- **Requisito/aspecto:** [ASP-04](../aspectos.md#asp-04--mensajeria-asincrona-y-auditoria)
- **Código:** [router de inventario](../../app/inventario/infrastructure/router.py),
  [broker simulador](../../app/messaging/broker_simulador.py) y
  [consumidor](../../app/main.py)
- **Pruebas:** [taller de mensajería](../../tests/messaging/test_taller_mensajeria.py),
  [contrato del evento](../../tests/messaging/test_contrato_evento.py) y
  [integración de inventario](../../tests/inventario/test_inventario.py)
- **Evidencia reproducible:** [evidencia del taller](../evidencia-mensajeria-s12.md)
