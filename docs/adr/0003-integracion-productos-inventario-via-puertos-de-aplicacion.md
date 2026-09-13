# ADR-0003: Integración productos–inventario vía puertos de aplicación

- **Estado:** Aceptado
- **Fecha:** 2026-09-13.
- **Decisores:** Equipo InvenTrack.

## Contexto

ASP-01 (Consistencia de datos) declara dos escenarios de calidad, ESC-01 y
ESC-02, que por definición requieren que los módulos `productos` e
`inventario` se coordinen:

- **ESC-02** exige que no se elimine físicamente un producto con movimientos
  de inventario asociados. Hoy `EliminarProducto` depende del puerto
  `VerificadorDeMovimientos`, pero su única implementación
  (`InMemoryVerificadorDeMovimientos`) es un doble de prueba que se marca a
  mano desde un endpoint auxiliar (`POST /productos/{id}/_marcar-con-movimientos`).
  No consulta ningún dato real de `inventario`.
- **ESC-01** y la integridad de `inventario` en general exigen que no se
  registren movimientos de stock para un producto que no existe o que ya fue
  desactivado. Hoy `RegistrarMovimientoInventario` acepta cualquier
  `producto_id` sin preguntarle nada a `productos`.

El [ADR-0001](0001-usar-monolito-modular-con-hexagonal-por-modulo.md) ya
estableció la regla de comunicación entre módulos: *"Los módulos no deben
importar directamente el `domain` o la `infrastructure` de otro módulo; la
comunicación se hará por contratos de aplicación"*. Este ADR no cambia esa
regla — la aplica por primera vez a un caso concreto.

## Alternativas consideradas

1. **Dejar los dobles de prueba como implementación "temporal" permanente.**
   Es lo que hay hoy. Se descarta porque dos escenarios de calidad centrales
   del proyecto quedarían certificados por pruebas que no ejercitan código
   real.
2. **Fusionar `productos` e `inventario` en un solo módulo.** Eliminaría el
   problema de integración, pero contradice el ADR-0001 y el árbol de
   utilidad, que los trata como dominios separados con dueños de datos
   distintos.
3. **Comunicación por eventos de dominio** (`inventario` publica
   `MovimientoRegistrado`, `productos` los escucha y acumula un historial
   propio). Es el patrón más desacoplado y el que mejor escalaría a
   microservicios, pero exige un bus de eventos (aunque sea en memoria),
   sincronización de estado duplicado, y resolver qué pasa si un evento se
   pierde — complejidad no justificada para un monolito de un solo proceso
   en esta etapa.
4. **Llamada síncrona directa entre las capas de aplicación de cada módulo**,
   envuelta en un puerto propio de cada módulo consumidor e implementada por
   un adaptador de infraestructura. Es el nivel mínimo de desacoplamiento
   que exige el ADR-0001 (import solo de `application`, nunca de `domain` o
   `infrastructure` ajenos) sin la complejidad operativa de un bus de
   eventos.

## Decisión

Se adopta la alternativa 4: **llamada síncrona entre capas de aplicación**,
mediada por un puerto propio en cada módulo consumidor.

### Dirección productos → inventario (resuelve ESC-02)

- `inventario` gana una entidad `Movimiento` y un puerto
  `MovimientoRepository`, con un caso de uso de lectura
  `ConsultarHistorialMovimientos`.
- `productos` mantiene su puerto `VerificadorDeMovimientos` (sin cambiar su
  interfaz), pero ahora se implementa con un adaptador
  (`HistorialMovimientosAdapter`) que en su constructor recibe e invoca
  `inventario.application.consultar_movimientos.ConsultarHistorialMovimientos`.
- El adaptador vive en `app/productos/infrastructure/`, y solo importa la
  capa `application` de `inventario` — nunca su `domain` ni su
  `infrastructure`, tal como exige el ADR-0001.
- Se elimina el endpoint de prueba `_marcar-con-movimientos` de la API real.

### Dirección inventario → productos (evita stock sobre productos inexistentes)

- `productos` gana un caso de uso de lectura `ConsultarProducto`.
- `inventario` gana un puerto `ValidadorDeProducto`, implementado por
  `ValidadorDeProductoAdapter`, que invoca
  `productos.application.consultar_producto.ConsultarProducto`.
- `RegistrarMovimientoInventario` valida contra ese puerto antes de tocar el
  stock, y rechaza con una nueva excepción `ProductoInvalidoError` si el
  producto no existe o está inactivo.

### Composición

Ambos adaptadores cruzados se ensamblan en `app/main.py` (o un contenedor de
composición dedicado), no dentro de los routers de cada módulo. Esto resuelve
de paso el wiring hardcodeado que hoy vive en
`productos/infrastructure/router.py` e `inventario/infrastructure/router.py`.

## Consecuencias positivas

- ESC-02 queda verificado contra el estado real de `inventario`, no contra un
  doble de prueba.
- Se cierra una vía de inconsistencia real: ya no se puede registrar stock
  para un producto inexistente o desactivado.
- La regla de comunicación entre módulos del ADR-0001 pasa de ser una
  intención declarada a tener un caso de uso real que la respeta.
- Los casos de uso de cada módulo (`ConsultarProducto`,
  `ConsultarHistorialMovimientos`) quedan disponibles para futuras
  necesidades (p. ej. `alertas` o `usuarios`) sin acoplarlos a HTTP.

## Consecuencias negativas y riesgos

- Aparece una dependencia de tiempo de ejecución entre módulos: si el caso de
  uso de un módulo lanza una excepción no controlada, puede propagarse al
  otro. Se mitiga con manejo explícito de errores en cada adaptador.
- El orden de composición en `app/main.py` importa: ambos módulos deben
  existir antes de construir los adaptadores cruzados. Si en el futuro se
  separan en procesos distintos (p. ej. microservicios), esta llamada directa
  tendría que migrar a HTTP interno o eventos — ese es exactamente el motivo
  por el que ADR-0001 ya advertía que la comunicación debía ir por contratos
  de aplicación y no por imports directos de dominio/infraestructura.
- No resuelve condiciones de carrera reales entre `productos` e `inventario`
  bajo escritura concurrente (ESC-01 completo); este ADR cubre la
  consistencia referencial y de lectura, no el control de concurrencia, que
  queda para un ADR posterior si el reto de un corte futuro lo exige.

## Evidencia inicial

- `app/inventario/domain/movimiento.py`, `app/inventario/domain/ports.py`
  (extendido), `app/inventario/infrastructure/in_memory_movimiento_repository.py`,
  `app/inventario/application/consultar_movimientos.py`.
- `app/productos/application/consultar_producto.py`,
  `app/productos/infrastructure/historial_movimientos_adapter.py`.
- `app/inventario/domain/ports.py` (puerto `ValidadorDeProducto`),
  `app/inventario/infrastructure/validador_producto_adapter.py`.
- `app/main.py` actualizado como único punto de composición cruzada.
- Pruebas nuevas: `tests/inventario/test_validacion_producto.py`,
  `tests/productos/test_historial_real.py`.
