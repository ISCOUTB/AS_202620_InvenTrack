# ADR-0015: Completar la decisión de almacenamiento y costo de reversión

- **Estado:** Aceptado
- **Fecha:** 2026-10-25
- **Decisores:** Equipo de Arquitectura InvenTrack (ISCOUTB)
- **Complementa:** [ADR-0012](0012-mantener-repositorios-en-memoria-en-el-mvp.md) y [ADR-0014](0014-estrategia-de-almacenamiento-y-costo-de-reversion.md)

## 1. Contexto y problema

El ADR-0014 aceptó repositorios en memoria, movimientos append-only y fronteras
hexagonales, pero no dejó completa la trazabilidad exigida por el contrato del
repositorio ni cuantificó las alternativas con el mismo criterio. Este ADR
complementario conserva la decisión técnica y documenta sus consecuencias,
costos, condiciones de revisión y evidencia navegable. El ADR-0014 queda
preservado sin modificaciones por la regla de inmutabilidad de ADRs aceptados.

## 2. Opciones evaluadas

1. **Repositorios en memoria durante el MVP:** costo operativo cero y velocidad
   local; pierde datos al reiniciar y no coordina réplicas.
2. **Base relacional desde el MVP:** persistencia durable desde el inicio;
   añade operación, credenciales, migraciones y costo antes de que exista una
   necesidad del escenario actual.
3. **Base independiente por módulo o servicio:** autonomía de despliegue;
   añade APIs/eventos, outbox, reintentos, consistencia distribuida y Sagas.

## 3. Decisión

Se mantiene la **Opción 1** en el MVP: repositorios en memoria encapsulados
por adaptadores, propiedad única de `Producto`, `StockProducto` y `Movimiento`,
y movimientos inmutables en el dominio. Los casos de uso no acceden directamente
a estructuras de almacenamiento ni a infraestructura de otro módulo.

La primera evolución a evaluar será una base relacional compartida mediante los
mismos puertos y adaptadores separados por módulo. Una base por servicio solo
se considerará si el crecimiento justifica asumir coordinación distribuida.

## 4. Costo de reversión y consecuencias

| Alternativa | Esfuerzo estimado | Datos afectados | Costo o complejidad |
|---|---:|---|---|
| Migrar de memoria a SQL después del MVP | 120–160 horas-hombre | No hay histórico durable; exige punto de corte y *seed* | Adaptadores SQL, esquema, migraciones, respaldos, restauración y operación |
| Adoptar SQL desde el MVP | 80–120 horas-hombre iniciales | Datos persistidos desde el comienzo | Dependencia operativa, credenciales, migraciones y costo mensual |
| Separar una base por módulo/servicio | 200–280 horas-hombre | Migración por contexto y reconciliación de referencias | APIs/eventos, outbox, reintentos y observabilidad distribuida |

Las cifras son estimaciones de planificación, no una medición de productividad.
La decisión actual minimiza el costo inicial, pero asume la pérdida de datos
volátiles hasta que exista una migración durable.

### Consecuencias positivas

- El MVP opera sin un servicio de datos externo y conserva el costo de $0.
- Los puertos permiten reemplazar adaptadores sin reescribir el dominio.
- La propiedad única evita que una migración cree tablas compartidas sin dueño.
- La inmutabilidad de `Movimiento` evita actualizaciones destructivas del
  historial dentro del modelo de dominio.

### Consecuencias negativas y deuda

- Reiniciar o redeplegar el proceso pierde productos, stock y movimientos.
- El lock por SKU solo protege una instancia.
- No existe recuperación ante desastres ni auditoría durable entre despliegues.
- La estimación no incluye recuperación de datos que nunca fueron persistidos.

## 5. Condiciones para revisar

Se debe crear otro ADR antes de habilitar una segunda réplica, requerir
recuperación después de reinicios, activar idempotencia durable o caché
compartida, superar la memoria disponible o seleccionar un motor concreto para
producción. El sucesor deberá incluir esquema, migración, respaldos,
restauración, concurrencia, observabilidad, costos y pruebas de recuperación.

## 6. Trazabilidad

- **Aspecto:** [ASP-01 Consistencia de datos](../aspectos.md#asp-01--consistencia-de-datos).
- **Requisitos:** ESC-01, ESC-02 y restricción C5.
- **C4:** [Nivel 2](../c4/containers.md), [Nivel 3](../c4/components.md) y
  [mapa de contextos](../context-map.md).
- **Código:** [repositorio de productos](../../app/productos/infrastructure/in_memory_repository.py),
  [repositorio de stock](../../app/inventario/infrastructure/in_memory_repository.py)
  y [repositorio de movimientos](../../app/inventario/infrastructure/in_memory_movimiento_repository.py).
- **Pruebas:** [inventario](../../tests/inventario/test_inventario.py),
  [concurrencia](../../tests/inventario/test_concurrencia.py),
  [corte vertical](../../tests/productos/test_api_corte_vertical.py) e
  [historial real](../../tests/productos/test_historial_real.py).
- **Evidencia:** [despliegue y costos](../despliegue-y-costos.md) y
  [fallos distribuidos S11](../retos/fallos-distribuidos-s11.md).
- **Relación histórica:** ADR-0014 se conserva sin editar y este ADR lo
  complementa para completar la decisión vigente sin reescribirlo.
- **Commit/PR:** se registrará al integrar este ADR en la rama principal; no se
  inventa un identificador.
