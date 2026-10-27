# Aspectos de Calidad

Este archivo sigue el modelo de trazabilidad visto en clase:

```
Aspecto → Requisito → C4 → ADR → Código → Pruebas → Evidencia
```

Un **aspecto** no es una capa del sistema ni un módulo — es un corte vertical, de punta a punta, que se puede recorrer completo: desde la necesidad que lo justifica hasta la evidencia que demuestra que se cumplió. La tabla de abajo tiene una fila por aspecto declarado, con las ocho columnas que exige el curso; cada celda enlaza al artefacto real.

---

## Tabla de trazabilidad

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|---|---|---|---|---|---|---|---|
| ASP-01 | [Consistencia de datos](#asp-01--consistencia-de-datos) | [ESC-01, ESC-02](arc42/arc42-template-EN.md#quality-scenarios) | [C4 Nivel 2](c4/containers.md), [C4 Nivel 3](c4/components.md), [Mapa de contextos](context-map.md), [Contrato de API](api/inventrack-contrato.md) — módulos `productos` e `inventario` | [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md), [ADR-0003](adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion.md), [ADR-0004](adr/0004-contrato-api-versionado-openapi.md), [ADR-0010](adr/0010-decision-extraccion-microservicios.md), [ADR-0011](adr/0011-idempotencia-y-sagas-en-movimientos.md), [ADR-0012](adr/0012-mantener-repositorios-en-memoria-en-el-mvp.md), [ADR-0014](adr/0014-estrategia-de-almacenamiento-y-costo-de-reversion.md), [ADR-0015](adr/0015-completar-decision-de-almacenamiento-y-reversion.md) | [`app/productos/`](../app/productos/), [`app/inventario/`](../app/inventario/) — Corte vertical funcional con integración real entre módulos | [`tests/productos/test_api_corte_vertical.py`](../tests/productos/test_api_corte_vertical.py), [`tests/productos/test_historial_real.py`](../tests/productos/test_historial_real.py), [`tests/inventario/test_validacion_producto.py`](../tests/inventario/test_validacion_producto.py), [`tests/inventario/test_concurrencia.py`](../tests/inventario/test_concurrencia.py), [`tests/contract/test_openapi_contract.py`](../tests/contract/test_openapi_contract.py) | [Evidencia S6 de integración real y defecto controlado](evidencia-ia-corte-s6.md), [matriz S12 de operaciones y caché](arc42/arc42-template-EN.md#cross-cutting-concepts-consistencia-concurrencia-y-estrategia-de-datos), prueba de corte vertical (API + Hexagonal) en verde contra el historial real de inventario ([`docs/propiedad-datos.md`](propiedad-datos.md), [`docs/auditoria-modularidad.md`](auditoria-modularidad.md)); decisión de persistencia, extracción e idempotencia en ADR-0010/0011/0012/0014/0015; contrato de API validado en CI (ADR-0004) |
| ASP-02 | [Control de Concurrencia e Inventario (Reto Corte 1)](#asp-02--control-de-concurrencia-e-inventario-reto-corte-1) | [ESC-01](arc42/arc42-template-EN.md#quality-scenarios) — Latencia $p95 \le 400\text{ ms}$ con 20 usuarios | [C4 Nivel 2](c4/containers.md), [C4 Nivel 3](c4/components.md), [Mapa de contextos](context-map.md), [Contrato de API](api/inventrack-contrato.md) — módulos `inventario` y `productos` | [ADR-0002](adr/0002-control-concurrencia-memoria-inventario.md) — Control de concurrencia en memoria para inventario | [`app/inventario/`](../app/inventario/) — Gestión de movimientos y stock atómico | [`tests/inventario/test_concurrencia.py`](../tests/inventario/test_concurrencia.py), [`tests/contract/test_openapi_contract.py`](../tests/contract/test_openapi_contract.py) | [`docs/retos/corte-2-experimento.md`](retos/corte-2-experimento.md) — prueba reproducible de 20 salidas reales que calcula p95 y exige $\le 400\text{ ms}$; el `503` y la evidencia del contrato están documentados en [`docs/api/inventrack-contrato.md`](api/inventrack-contrato.md) y [`docs/evidencia-prueba-contrato.md`](evidencia-prueba-contrato.md) |
| ASP-03 | [Observabilidad de latencia](#asp-03--observabilidad-de-latencia) | [ESC-04](arc42/arc42-template-EN.md#quality-scenarios) — p95 $\le 400\text{ ms}$ en estado caliente | [C4 Nivel 2](c4/containers.md), [Vista de despliegue](arc42/arc42-template-EN.md#7-deployment-view) — API y `/metrics` | [ADR-0007](adr/0007-exponer-p95-de-latencia-en-metricas.md) — Exponer p95 de latencia en métricas HTTP | [`app/main.py`](../app/main.py) — cálculo `_p95_latency` y métrica Prometheus | [`tests/test_metrics.py`](../tests/test_metrics.py) | [Evidencia S9 de porción, defecto y medición](evidencia-ia-corte-s9.md) |
| ASP-04 | [Mensajería asíncrona y auditoría](#asp-04--mensajeria-asincrona-y-auditoria) | Desacoplar la auditoría de entradas y salidas, conservar trazabilidad y tolerar duplicados y fallos recuperables | [C4 Nivel 2](c4/containers.md), [C4 Nivel 3](c4/components.md) — API de inventario, broker simulado y consumidor de auditoría | [ADR-0013](adr/0013-evaluacion-mensajeria-asincrona-vs-sincrona.md), [ADR-0016](adr/0016-integrar-eventos-de-auditoria-en-movimientos.md) | [`app/inventario/infrastructure/router.py`](../app/inventario/infrastructure/router.py), [`app/messaging/broker_simulador.py`](../app/messaging/broker_simulador.py), [`app/main.py`](../app/main.py), [`contracts/events/movimiento_registrado_v1.json`](../contracts/events/movimiento_registrado_v1.json) | [`tests/messaging/test_taller_mensajeria.py`](../tests/messaging/test_taller_mensajeria.py), [`tests/messaging/test_contrato_evento.py`](../tests/messaging/test_contrato_evento.py), [`tests/inventario/test_inventario.py`](../tests/inventario/test_inventario.py) | [Evidencia reproducible del taller](evidencia-mensajeria-s12.md) |

---

## ASP-01 — Consistencia de datos

### Descripción

El sistema debe garantizar que las operaciones sobre los productos y movimientos de inventario realizados de forma concurrente o condicional por distintos usuarios no dejen el dominio en un estado inconsistente. Casos concretos que este aspecto busca prevenir:

- Un producto con historial de movimientos es eliminado físicamente de la base de datos, perdiendo la trazabilidad de transacciones pasadas.
- Dos usuarios registran una salida del mismo producto al mismo tiempo y el stock queda descontado solo una vez (o descontado de más).
- Un producto queda con stock negativo por una condición de carrera entre dos transacciones simultáneas.

---

### Por qué se eligió este aspecto

En un sistema de inventarios, la confianza en el dato es el valor central del producto. Un sistema que reporta cifras incorrectas o pierde el historial transaccional genera falsa seguridad. Por eso la consistencia no es un "extra" técnico, sino el requisito principal que justifica la existencia misma del sistema frente a la alternativa manual (Excel).

---

### Requisito: escenarios de calidad

Este aspecto se refinó en dos escenarios de calidad medibles, documentados en [`docs/arc42/arc42-template-EN.md`](arc42/arc42-template-EN.md) y en el [árbol de utilidad](utility-tree.md):

- **ESC-01 — Registro simultáneo de salida del mismo producto** *(prioridad: alta)*. Dos empleados registran una salida del mismo producto al mismo tiempo; el sistema debe serializar las transacciones y aplicar ambos descuentos de forma consistente, o rechazar una si el stock resultante sería negativo.
- **ESC-02 — Eliminar producto con movimientos asociados** *(prioridad: media)*. Un administrador intenta eliminar un producto con historial de movimientos; el sistema debe impedir el borrado físico y permitir solo desactivación (borrado lógico), preservando la trazabilidad. Medida: verificado con prueba automatizada sobre el 100 % de los casos.

---

### Operación: garantía de consistencia

| Operación | Garantía de consistencia | Mecanismo | Límite conocido en el MVP |
|---|---|---|---|
| `POST /productos` | No se crean dos productos con el mismo identificador en una instancia. | Consulta previa del repositorio y rechazo de identificador existente. | [Prueba de API](../tests/productos/test_api_corte_vertical.py). Repositorio volátil y sin coordinación entre réplicas. |
| `DELETE /productos/{producto_id}` | Se preserva la trazabilidad; los productos con movimientos se desactivan. | `VerificadorDeMovimientos` decide entre borrado físico y lógico. | [Prueba de historial real](../tests/productos/test_historial_real.py). Una segunda solicitud puede devolver `404`. |
| `POST /inventario/{producto_id}/entradas` | Stock y movimiento se actualizan serializadamente; la misma clave HTTP no reaplica el comando. | Validación de producto activo, `asyncio.Lock` por SKU e `InMemoryIdempotencyStore` por clave. | [Pruebas de idempotencia](../tests/inventario/test_inventario.py). Solo una instancia; claves y resultados se pierden al reiniciar. |
| `POST /inventario/{producto_id}/salidas` | No se produce stock negativo y la misma clave HTTP no reaplica el comando. | Comprobación de disponibilidad, lock por SKU y fingerprint de operación/producto/cantidad. | [Pruebas de inventario e idempotencia](../tests/inventario/test_inventario.py). Timeout de 2 s devuelve `503`; coordinación entre réplicas pendiente. |
| `GET /inventario/{producto_id}` | Devuelve el saldo local sin modificarlo. | Consulta directa al repositorio de stock. | [Prueba de inventario](../tests/inventario/test_inventario.py). No es lectura distribuida ni durable. |

La tabla distingue la garantía funcional de su alcance operativo: el MVP protege la
consistencia inmediata y la idempotencia de comandos dentro de un proceso, pero
no ofrece deduplicación durable ni coordinación entre réplicas. Estas
capacidades quedan condicionadas a la evolución descrita en los
[ADR-0011](adr/0011-idempotencia-y-sagas-en-movimientos.md) y
[ADR-0017](adr/0017-idempotencia-http-en-comandos-de-inventario.md).

---

### Diseño de caché y política de invalidación

La caché es una evolución para cuando el catálogo y las consultas de inventario
sean suficientemente frecuentes para justificar el costo de una segunda fuente
de lectura. No se incorpora al MVP actual, cuyos repositorios son en memoria.
Cuando se habilite, el origen de verdad seguirá siendo el repositorio del módulo
dueño y la caché se usará únicamente como acelerador de lecturas.

#### Estrategia y alcance

- **Patrón:** *cache-aside*. El caso de uso consulta la caché; ante un *miss*,
  lee el repositorio dueño y guarda el resultado con TTL.
- **Implementación objetivo:** Redis compartido entre réplicas, no un diccionario
  local por proceso. Esto evita que cada instancia observe una versión distinta
  después de una escritura.
- **Datos cacheables:** `Producto` y `StockProducto` por identificador. Los
  `Movimiento` no se cachean por defecto: son un historial inmutable que debe
  conservar lectura directamente desde su repositorio hasta contar con una
  estrategia explícita de paginación y versionado.
- **Clave y versión:** `inventrack:v1:producto:{producto_id}` y
  `inventrack:v1:stock:{producto_id}`. El prefijo permite invalidar por versión
  durante cambios de esquema sin mezclar valores incompatibles.
- **TTL inicial:** 5 minutos para producto y 5 segundos para stock. El TTL de
  stock es una barrera de seguridad, no la garantía principal de consistencia:
  toda escritura debe invalidarlo inmediatamente.

#### Política de invalidación

| Operación | Claves afectadas | Política | Orden requerido |
|---|---|---|---|
| `POST /productos` | `producto:{producto_id}` | No se precarga la caché. El primer `GET` posterior hace *miss* y carga el valor persistido. | Persistir primero; la caché nunca confirma la escritura. |
| `DELETE /productos/{producto_id}` con borrado físico | `producto:{producto_id}`, `stock:{producto_id}` | Eliminar ambas claves. Cualquier lectura posterior debe volver al origen y recibir `404`. | Completar el borrado; después invalidar. |
| `DELETE /productos/{producto_id}` con desactivación | `producto:{producto_id}` | Eliminar la representación cacheada para que no se sirva como activa. | Persistir el estado inactivo; después invalidar. |
| `POST /inventario/{producto_id}/entradas` | `stock:{producto_id}` | Invalidación exacta del SKU modificado; no se conserva el saldo anterior. | Registrar el movimiento y guardar el stock bajo el lock; después invalidar. |
| `POST /inventario/{producto_id}/salidas` | `stock:{producto_id}` | Invalidación exacta del SKU modificado, tanto si el descuento es aceptado como si cambia el estado observado por una regla de negocio. | Solo invalidar después de una escritura exitosa; ante rechazo no modificar la caché. |
| `GET /productos/{producto_id}` o `GET /inventario/{producto_id}` | La clave correspondiente | *Cache hit* devuelve el valor mientras su TTL sea válido; *cache miss* consulta el origen y repuebla. | Nunca escribir directamente en caché sin validar el origen. |

La invalidación debe ser **síncrona dentro de la respuesta de escritura**. Si el
repositorio se actualiza pero Redis no está disponible, la operación de negocio
no se revierte ni se confirma una versión falsa: se registra el error, se
continúa sin caché y la siguiente lectura debe consultar el origen. Si no es
posible garantizar que una entrada potencialmente obsoleta fue eliminada, el
adaptador debe aplicar *fail-safe* para esa clave (no servirla) hasta que expire
o pueda invalidarse.

#### Garantías y límites

- Las operaciones de escritura siguen protegidas por el `asyncio.Lock` por SKU;
  la caché no reemplaza el lock ni participa en la decisión de stock suficiente.
- Una salida o entrada exitosa no puede dejar deliberadamente un saldo antiguo
  en caché: la invalidación ocurre después de guardar el nuevo saldo.
- El TTL limita la permanencia accidental de datos obsoletos, pero no sustituye
  la invalidación. La consistencia fuerte de stock se obtiene leyendo el origen
  después de un *miss*.
- La caché no implementa idempotencia, no coordina sagas y no debe almacenar
  respuestas de comandos `POST` o `DELETE`.
- La activación requiere métricas de *hit rate*, *miss rate*, errores de Redis,
  invalidaciones y edad de la entrada, además de pruebas de escritura seguida
  de lectura y de fallo del proveedor de caché.

Este diseño queda condicionado a incorporar persistencia compartida y una
decisión arquitectónica específica antes de escalar horizontalmente; mientras
el sistema opere con repositorios en memoria, la política efectiva es
**sin caché**.

---

### C4: dónde vive este aspecto

El [diagrama de contenedores (C4 Nivel 2)](c4/containers.md) y el [diagrama de contexto (C4 Nivel 1)](c4/context.md) muestran que este aspecto vive en la capa de Backend (`API Backend (Monolito Modular)`), la cual expone las reglas de negocio hacia la interfaz mediante el [Contrato de API](api/inventrack-contrato.md). En la estructura del código, se implementó como corte vertical en los módulos [`app/productos/`](../app/productos/) e [`app/inventario/`](../app/inventario/), desacoplados mediante puertos y adaptadores según el [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md). El [C4 Nivel 3](c4/components.md) abre esos dos módulos hasta el nivel de componente, y el [mapa de contextos](context-map.md) documenta la relación cliente-proveedor entre ambos, tipificada según el [ADR-0003](adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion.md).

---

### ADR: decisiones aplicadas

El [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md) resuelve la arquitectura interna del código, garantizando que el dominio esté protegido de dependencias externas:

- **Casos de uso aislados:** `CrearProducto` y `EliminarProducto` coordinan las reglas del sistema.
- **Borrado lógico vs. borrado físico:** La regla de negocio valida si existen movimientos asociados antes de permitir la eliminación física o forzar la desactivación (`ESC-02`).

El [ADR-0003](adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion.md) resuelve cómo `productos` obtiene ese dato de movimientos sin importar el `domain` ni la `infrastructure` de `inventario` (y, en sentido contrario, cómo `inventario` valida que un producto exista antes de aceptar un movimiento). Ver el detalle de esta violación y su corrección en [`docs/auditoria-modularidad.md`](auditoria-modularidad.md) (VIO-01) y la propiedad de cada dato en [`docs/propiedad-datos.md`](propiedad-datos.md):

- **`HistorialMovimientosAdapter`** (`app/productos/infrastructure/`) implementa el puerto `VerificadorDeMovimientos` de `productos` invocando el caso de uso `ConsultarHistorialMovimientos` de `inventario`.
- **`ValidadorDeProductoAdapter`** (`app/inventario/infrastructure/`), en la dirección contraria, invoca `ConsultarProducto` de `productos` para evitar que `inventario` registre movimientos sobre productos inexistentes o desactivados.

---

### Código y pruebas (Corte Vertical Implementado)

El módulo [`app/productos/`](../app/productos/) contiene el corte vertical funcional completo:
- **Dominio y Puertos:** `app/productos/domain/` (`producto.py`, `ports.py`, `exceptions.py`).
- **Aplicación:** `app/productos/application/` (`crear_producto.py`, `eliminar_producto.py`, `consultar_producto.py`).
- **Infraestructura y REST API:** `app/productos/infrastructure/` (`router.py`, `in_memory_repository.py`, `historial_movimientos_adapter.py`).

El módulo [`app/inventario/`](../app/inventario/) aporta el dato real que `productos` necesita para ESC-02:
- **Dominio y Puertos:** `app/inventario/domain/` (`stock.py`, `movimiento.py`, `ports.py`, `exceptions_producto.py`).
- **Aplicación:** `app/inventario/application/` (`registrar_movimiento.py`, `consultar_movimientos.py`).
- **Infraestructura:** `app/inventario/infrastructure/` (`router.py`, `in_memory_repository.py`, `in_memory_movimiento_repository.py`, `validador_producto_adapter.py`).

El aspecto está cubierto y validado mediante la suite de pruebas automatizadas:
- **Integración de Corte Vertical (E2E), contra el historial real de inventario:** [`tests/productos/test_api_corte_vertical.py`](../tests/productos/test_api_corte_vertical.py)
- **Pruebas de Unidad de Dominio (productos):** [`tests/productos/test_eliminar_producto.py`](../tests/productos/test_eliminar_producto.py)
- **Prueba del adaptador cruzado (ADR-0003):** [`tests/productos/test_historial_real.py`](../tests/productos/test_historial_real.py)
- **Pruebas de validación de producto en inventario (ADR-0003):** [`tests/inventario/test_validacion_producto.py`](../tests/inventario/test_validacion_producto.py)

---

### Estado

- [x] Aspecto identificado y declarado
- [x] Escenarios de calidad definidos (ESC-01, ESC-02)
- [x] Diagrama C4 Nivel 2 y Nivel 3 delimitados y vinculados
- [x] Módulos del corte vertical implementados (`app/productos/`, `app/inventario/`)
- [x] Reglas de consistencia (borrado lógico/físico ESC-02) implementadas
- [x] Pruebas de integración E2E del corte vertical en verde
- [x] ESC-02 verificado contra datos reales de `inventario`, no contra un doble de prueba (ADR-0003)
- [x] `inventario` valida que el producto exista y esté activo antes de registrar un movimiento (ADR-0003)

---

## ASP-02 — Control de Concurrencia e Inventario (Reto Corte 1)

### Descripción y Diagnóstico del Reto

Garantizar la actualización atómica del stock y la prevención de condiciones de carrera (*race conditions*) cuando múltiples peticiones concurrentes intentan registrar movimientos de inventario sobre el mismo producto (SKU), asegurando que el tiempo de respuesta en el percentil 95 ($p95$) no supere los $400\text{ ms}$.

Para alinearse rigurosamente con la evaluación técnica, el diagnóstico se desglosa en:
- **Síntoma:** Bajo carga simultánea sobre un mismo SKU, se presentan lecturas/escrituras solapadas que generan stock negativo o descuadres en la cifra final de inventario.
- **Causa Raíz:** Ausencia de un mecanismo de serialización / exclusión mutua asíncrona sobre el repositorio en memoria durante operaciones concurrentes.
- **Riesgo Prioritario:** Pérdida de integridad del dato central del negocio (el stock) y degradación de la latencia por peticiones bloqueadas o fallidas.
- **Línea Base Histórica Declarada:** La documentación del reto describe escrituras sucias (*dirty writes*) antes del lock, pero esa ejecución previa no está disponible como artefacto reproducible en el repositorio. La prueba vigente fija el umbral en ráfagas de 20 peticiones concurrentes con $p95 \le 400\text{ ms}$ y 0 descuadres.

---

### Por qué se eligió este aspecto

Atiende directamente la restricción asignada para el **Corte 1**. Demuestra cómo la arquitectura monolítica modular soporta aislamiento transaccional a nivel de aplicación sin comprometer los tiempos de respuesta exigidos por los escenarios de calidad del sistema.

---

### Requisito: escenario de calidad

- **ESC-01 (Rendimiento y Concurrencia):** 20 peticiones simultáneas reduciendo inventario sobre el mismo SKU.
- **Umbral de Aceptación:** Latencia $p95 \le 400\text{ ms}$ y stock final resultante exacto (cero inconsistencias o descuadres).

---

### C4: dónde vive este aspecto

Vive en la interacción entre los módulos `app/inventario/` y `app/productos/` dentro del contenedor de la **API Backend (FastAPI)** [C4 Nivel 2](c4/containers.md), cuyos endpoints y respuestas están normados en el [Contrato de API](api/inventrack-contrato.md).

---

### ADR: decisiones aplicadas

El [ADR-0002](adr/0002-control-concurrencia-memoria-inventario.md) establece el mecanismo de **exclusión mutua (Mutex/Lock asíncrono) por SKU** en la capa de aplicación/dominio, evitando condiciones de carrera en memoria.

---

### Degradación Controlada y Resiliencia

En caso de que la carga supere la capacidad de atención o el tiempo de espera por el cerrojo asíncrono exceda el límite razonable:
- El sistema encola ordenadamente las peticiones sobre el *event loop* de FastAPI sin bloquear el hilo principal.
- Ante un timeout de espera sobre el lock, el servicio responde HTTP `503 Service Unavailable`, protegiendo la consistencia del inventario y evitando el colapso del proceso (documentado en el [Contrato de API](api/inventrack-contrato.md)).

---

### Código, Pruebas y Evidencia

- **Código:** Módulos de [`app/inventario/`](../app/inventario/) y [`app/productos/`](../app/productos/).
- **Prueba Automatizada:** [`tests/inventario/test_concurrencia.py`](../tests/inventario/test_concurrencia.py) (simula 20 llamadas asíncronas concurrentes).
- **Evidencia Medida:** Reporte en [`docs/retos/corte-1-medicion.md`](retos/corte-1-medicion.md) que acredita $p95 = 28\text{ ms}$ bajo carga (superando ampliamente el umbral exigido de $400\text{ ms}$).

---

### Estado

- [x] Aspecto de concurrencia e inventario declarado
- [x] Diagnóstico técnico detallado (Síntoma, Causa Raíz, Riesgo y línea base histórica declarada)
- [x] Escenario de rendimiento verificado (ESC-01)
- [x] Decisiones de arquitectura registradas en ADR-0002
- [x] Módulo `app/inventario/` integrado a la trazabilidad
- [x] Estrategia de degradación controlada documentada
- [x] Prueba automatizada de 20 peticiones concurrentes en verde
- [x] Reporte de medición reproducible publicado en la documentación

---

## ASP-03 — Observabilidad de latencia

### Requisito y decisión

El escenario **ESC-04** exige observar el percentil 95 de latencia y mantenerlo
en $400\text{ ms}$ o menos en estado caliente. El [ADR-0007](adr/0007-exponer-p95-de-latencia-en-metricas.md)
decide extraer el cálculo a `_p95_latency`, conservar el historial acotado y
publicar el resultado mediante `/metrics`, sin agregar dependencias externas.

### Código, prueba y evidencia

- **Código:** [`app/main.py`](../app/main.py), función `_p95_latency` y métrica
	`inventrack_http_p95_latency_seconds`.
- **Prueba:** [`tests/test_metrics.py`](../tests/test_metrics.py), que detecta el
	índice incorrecto del percentil.
- **Evidencia:** [`docs/evidencia-ia-corte-s9.md`](evidencia-ia-corte-s9.md),
	con el defecto controlado y la medición contrastada con ESC-04.

### Estado

- [x] Aspecto y escenario ESC-04 declarados
- [x] ADR-0007 aceptado y enlazado
- [x] Código y prueba de la porción S9 enlazados
- [x] Defecto controlado reproducible y restaurado
- [x] Medición documentada frente al umbral de 400 ms