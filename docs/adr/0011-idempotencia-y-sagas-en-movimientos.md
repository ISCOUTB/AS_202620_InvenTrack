# ADR-0011: Idempotencia de movimientos y no uso de Saga en el MVP

- **Estado:** Aceptado
- **Fecha:** 2026-10-18
- **Decisores:** Equipo InvenTrack
- **Complementa:** [ADR-0002](0002-control-concurrencia-memoria-inventario.md), [ADR-0003](0003-integracion-productos-inventario-via-puertos-de-aplicacion.md) y [ADR-0010](0010-decision-extraccion-microservicios.md)

## Contexto

Los endpoints de entradas y salidas modifican stock y registran movimientos. Un
cliente que repita una solicitud después de un timeout de red podría aplicar el
mismo movimiento más de una vez. La exclusión mutua por SKU evita carreras,
pero no identifica reintentos duplicados.

El MVP actual es un monolito modular con repositorios en memoria y una llamada
síncrona entre casos de uso. No existe una transacción distribuida entre
servicios que requiera una Saga.

## Opciones evaluadas

1. **Agregar una Saga ahora.** Se descarta: no hay servicios independientes ni
   pasos distribuidos que coordinar en el MVP.
2. **Agregar idempotencia persistente ahora.** Se descarta temporalmente: exige
   almacenamiento durable de claves y resultados, ausente en el MVP en memoria.
3. **Mantener comandos no idempotentes explícitos y preparar el contrato para
   una evolución futura.** Se adopta para el MVP, documentando el límite y la
   condición que activa la siguiente decisión.

## Decisión

No se implementa una Saga mientras `productos` e `inventario` permanezcan en el
mismo proceso y la operación sea solicitud-respuesta síncrona. La consistencia
actual se protege con validación de dominio y `asyncio.Lock` por SKU.

Los comandos `POST /inventario/{producto_id}/entradas` y
`POST /inventario/{producto_id}/salidas` se consideran **no idempotentes** en
esta versión: un cliente no debe reintentar automáticamente una solicitud cuyo
resultado desconoce. La API no promete deduplicación por `Idempotency-Key`.

Antes de extraer `inventario` o habilitar reintentos automáticos, se debe crear
una evolución que:

- acepte una clave de idempotencia por comando;
- persista la clave junto con el resultado y el identificador del movimiento;
- devuelva el mismo resultado ante la repetición de la misma clave y payload;
- rechace la reutilización de una clave con un payload diferente;
- defina una Saga u Outbox únicamente si el movimiento cruza límites de servicio
  y requiere coordinación distribuida.

## Consecuencias

- El MVP evita complejidad distribuida que no necesita.
- Un reintento HTTP de una entrada o salida puede duplicar el movimiento; es un
  riesgo conocido y debe ser considerado por los clientes actuales.
- La extracción a microservicios queda condicionada a resolver primero la
  deduplicación durable y, si aparecen pasos distribuidos, la coordinación
  mediante Saga u Outbox.

## Trazabilidad

- **Aspecto y requisito:** [ASP-01](../aspectos.md#asp-01--consistencia-de-datos),
  ESC-01 y la evolución de consistencia distribuida antes de extraer módulos.
- **C4:** [C4 Nivel 2](../c4/containers.md), [C4 Nivel 3](../c4/components.md)
  y [mapa de contextos](../context-map.md).
- **Código actual:** `app/inventario/application/registrar_movimiento.py` y
  `app/inventario/infrastructure/router.py`.
- **Pruebas actuales:** `tests/inventario/test_concurrencia.py` y
  `tests/inventario/test_inventario.py`.
- **Riesgo:** tabla de modos de fallo en
  `docs/arc42/arc42-template-EN.md`.
- **Implementación:** este ADR y sus enlaces se incorporan en la entrega actual;
  el commit o PR de publicación debe registrarse al integrar el cambio.
- **Decisión relacionada:** [ADR-0010](0010-decision-extraccion-microservicios.md).
