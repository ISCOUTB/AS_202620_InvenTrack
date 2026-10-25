# ADR-0012: Mantener repositorios en memoria en el MVP

- **Estado:** Pendiente
- **Fecha:** 2026-10-25
- **Decisores:** Equipo de Arquitectura InvenTrack (ISCOUTB)
- **Complementa:** [ADR-0001](0001-usar-monolito-modular-con-hexagonal-por-modulo.md), [ADR-0002](0002-control-concurrencia-memoria-inventario.md), [ADR-0003](0003-integracion-productos-inventario-via-puertos-de-aplicacion.md) y [ADR-0010](0010-decision-extraccion-microservicios.md)

## 1. Contexto y problema

InvenTrack necesita almacenar productos, existencias y movimientos. La
implementación actual usa repositorios en memoria dentro de un monolito modular:
`productos` es dueño de `Producto` e `inventario` es dueño de `StockProducto` y
`Movimiento`. Los módulos consultan datos ajenos únicamente mediante puertos de
aplicación.

Elegir ahora una estrategia de persistencia durable y una topología de datos
sería la decisión de datos más costosa de revertir. No solo implica elegir un
motor: también fija migraciones, transacciones, índices, respaldo y
recuperación, observabilidad, costos operativos y el modo en que se coordinan
las escrituras entre módulos. Por tanto, esta decisión debe separar el alcance
del MVP de la ruta de evolución sin romper la propiedad de los datos.

## 2. Opciones evaluadas

### Opción A: Mantener repositorios en memoria en el MVP

- Conservar `InMemoryProductoRepository`, `InMemoryStockRepository` e
  `InMemoryMovimientoRepository`.
- Mantener la propiedad única de cada agregado y los puertos de aplicación.
- Aceptar que un reinicio o redeploy pierde los datos.

### Opción B: Una base relacional compartida con esquemas por módulo

- Incorporar PostgreSQL como dependencia operativa.
- Mantener la separación lógica mediante tablas o esquemas propiedad de cada
  módulo, con transacciones locales al módulo.
- Añadir migraciones, respaldos, credenciales, monitoreo y estrategia de
  recuperación antes de considerar la opción lista para producción.

### Opción C: Una base de datos por módulo o servicio

- Asignar un almacenamiento independiente a `productos` y `inventario`.
- Cambiar las consultas cruzadas por APIs, eventos o una proyección local.
- Resolver consistencia distribuida, reintentos, outbox y posibles Sagas.

## 3. Decisión adoptada

Se selecciona la **Opción A: mantener los repositorios en memoria en el MVP**.
La decisión se limita al almacenamiento actual y no autoriza que un módulo
escriba directamente los datos de otro.

La evolución preferida, cuando la pérdida de datos ya no sea aceptable, será
evaluar primero la **Opción B**: persistencia relacional compartida con
propiedad de datos y adaptadores separados por módulo. La Opción C solo se
considerará si existen límites de escalamiento, despliegue o autonomía que
justifiquen asumir consistencia distribuida.

La migración futura deberá conservar los puertos de repositorio y reemplazar
los adaptadores de infraestructura. No se permite migrar copiando consultas
directamente entre módulos ni trasladando la propiedad de `StockProducto` o
`Movimiento` a `productos`.

## 4. Criterios de decisión

1. **Costo operativo:** el MVP debe respetar C5 y operar sin una base de datos
   administrada adicional.
2. **Consistencia local:** el lock por SKU de [ADR-0002](0002-control-concurrencia-memoria-inventario.md)
   funciona dentro de una sola instancia y no requiere coordinación externa.
3. **Simplicidad del corte vertical:** los repositorios actuales permiten
   verificar el flujo API, dominio, integración por puertos y pruebas sin
   introducir infraestructura no necesaria para los escenarios vigentes.
4. **Reversibilidad controlada:** aunque la pérdida de datos es un límite serio,
   los puertos y la propiedad única reducen el acoplamiento que deberá
   modificarse al incorporar persistencia durable.
5. **Costo de la alternativa distribuida:** la Opción C añadiría fallos de red,
   consistencia eventual y coordinación de operaciones antes de que exista una
   necesidad de negocio.

## 5. Consecuencias

### Positivas

- Se mantiene el costo operativo del MVP en cero y el despliegue actual no
  requiere un servicio de datos adicional.
- Las operaciones de inventario conservan consistencia inmediata dentro de una
  instancia mediante el `asyncio.Lock` por SKU.
- Los módulos mantienen límites explícitos de propiedad, compatibles con una
  futura migración mediante adaptadores.
- Se evita introducir prematuramente migraciones, credenciales, respaldos y
  coordinación distribuida.

### Negativas y deuda asumida

- Un reinicio, redeploy o caída del proceso pierde productos, stock y
  movimientos.
- No existe recuperación ante desastres, auditoría durable ni consultas
  históricas entre despliegues.
- El lock en memoria no protege escrituras concurrentes entre réplicas.
- Antes de activar escalamiento horizontal o la caché compartida descrita en
  [docs/aspectos.md](../aspectos.md#diseño-de-caché-y-política-de-invalidación),
  se debe resolver la persistencia y la coordinación de versiones.
- La migración futura requerirá definir un esquema, ejecutar backfill o aceptar
  un punto de corte, probar transacciones y establecer respaldos y restauración.

## 6. Condiciones que obligan a revisar la decisión

Se debe abrir un ADR sucesor si ocurre cualquiera de estas condiciones:

- La pérdida de datos tras un reinicio deja de ser aceptable para un usuario o
  requisito de calidad.
- Se requiere más de una réplica del backend.
- El volumen de movimientos supera la memoria disponible o exige consultas
  históricas durables.
- Se habilitan reintentos automáticos, idempotencia durable o una caché
  compartida.
- El despliegue deja de cumplir C5 y permite incorporar una base de datos
  administrada o institucional.

## 7. Trazabilidad

- **Aspecto y requisito:** [ASP-01 Consistencia de datos](../aspectos.md#asp-01--consistencia-de-datos),
  especialmente ESC-01 y ESC-02; la propiedad de datos está documentada en
  [docs/propiedad-datos.md](../propiedad-datos.md).
- **C4:** [C4 Nivel 2](../c4/containers.md), [C4 Nivel 3](../c4/components.md)
  y [mapa de contextos](../context-map.md).
- **Código actual:** [app/productos/infrastructure/in_memory_repository.py](../../app/productos/infrastructure/in_memory_repository.py),
  [app/inventario/infrastructure/in_memory_repository.py](../../app/inventario/infrastructure/in_memory_repository.py) y
  [app/inventario/infrastructure/in_memory_movimiento_repository.py](../../app/inventario/infrastructure/in_memory_movimiento_repository.py).
- **Pruebas:** [tests/inventario/test_concurrencia.py](../../tests/inventario/test_concurrencia.py),
  [tests/inventario/test_inventario.py](../../tests/inventario/test_inventario.py),
  [tests/productos/test_api_corte_vertical.py](../../tests/productos/test_api_corte_vertical.py)
  y [tests/productos/test_historial_real.py](../../tests/productos/test_historial_real.py).
- **Evidencia y límites operativos:** [docs/despliegue-y-costos.md](../despliegue-y-costos.md),
  sección de punto de quiebre.
- **Implementación:** este ADR documenta la decisión vigente; el commit o PR de
  publicación debe registrarse al integrar el cambio.

