# ADR-0017: Idempotencia HTTP en comandos de inventario

- **Estado:** Aceptado
- **Fecha:** 2026-10-27
- **Decisores:** Equipo InvenTrack
- **Desarrolla:** [ADR-0011](0011-idempotencia-y-sagas-en-movimientos.md)

## Contexto

El consumidor de auditoría ya deduplica eventos, pero eso ocurre después de que
el caso de uso modificó el stock. Por tanto, repetir un `POST` con la misma
clave podría duplicar el movimiento aunque la auditoría se procese una sola vez.
La revisión de S12 exige separar la idempotencia del comando HTTP de la
deduplicación del evento.

## Opciones evaluadas

1. **No deduplicar comandos:** mantiene el MVP simple, pero permite doble
   aplicación después de un timeout de red.
2. **Registro de idempotencia en memoria:** reserva la clave antes del caso de
   uso, guarda fingerprint y resultado, y permite replay dentro del proceso.
   No añade infraestructura, pero se pierde al reiniciar.
3. **Registro durable con PostgreSQL/Redis u Outbox:** sobrevive reinicios y
   réplicas, pero exige persistencia compartida, migraciones y operación
   adicional.

## Decisión

Se adopta la opción 2 para el MVP. `X-Idempotency-Key` identifica el comando
HTTP y el fingerprint incluye operación, producto y cantidad.

- Primera solicitud: reserva la clave, ejecuta el movimiento y guarda el
  resultado.
- Repetición con la misma clave y fingerprint: devuelve el resultado original y
  no modifica el stock ni publica otro evento.
- Misma clave con fingerprint diferente: responde `409 Conflict`.
- Entregas concurrentes: un lock por clave garantiza que solo una ejecute el
  caso de uso.
- Sin cabecera: se conserva el comportamiento anterior y cada solicitud genera
  un evento independiente.

El registro es volátil. Un reinicio elimina las claves y resultados; antes de
usar varias réplicas o exigir recuperación ante fallos se debe migrar a un
registro durable y definir su transacción con el movimiento, preferiblemente
mediante una Outbox.

## Ventana entre stock y publicación

El stock y el movimiento se guardan antes de agendar la auditoría con
`BackgroundTasks`. Si el proceso cae en esa ventana, el estado de inventario
puede persistir en RAM mientras el evento no llega al broker. El simulador y su
DLQ no sobreviven al reinicio. Esta pérdida potencial es explícita y no se
presenta como garantía durable; la corrección futura es una Outbox durable.

## Trazabilidad

- **Aspecto:** [ASP-01](../aspectos.md#asp-01--consistencia-de-datos)
- **Código:** [idempotency.py](../../app/inventario/infrastructure/idempotency.py),
  [router.py](../../app/inventario/infrastructure/router.py)
- **Pruebas:** [test_inventario.py](../../tests/inventario/test_inventario.py)
- **Evidencia:** [evidencia-mensajeria-s12.md](../evidencia-mensajeria-s12.md)
