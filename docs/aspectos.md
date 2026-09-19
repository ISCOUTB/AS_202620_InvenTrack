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
| ASP-01 | [Consistencia de datos](#asp-01--consistencia-de-datos) | [ESC-01, ESC-02](arc42/arc42-template-EN.md#quality-scenarios) | [C4 Nivel 2](c4/containers.md), [C4 Nivel 3](c4/components.md), [Mapa de contextos](context-map.md), [Contrato OpenAPI](../contracts/openapi/v1.json) — módulos `productos` e `inventario` | [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md), [ADR-0003](adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion.md), [ADR-0004](adr/0004-contrato-api-versionado-openapi.md) | [`app/productos/`](../app/productos/), [`app/inventario/`](../app/inventario/) — Corte vertical funcional con integración real entre módulos | [`tests/productos/test_api_corte_vertical.py`](../tests/productos/test_api_corte_vertical.py), [`tests/productos/test_historial_real.py`](../tests/productos/test_historial_real.py), [`tests/inventario/test_validacion_producto.py`](../tests/inventario/test_validacion_producto.py), [`tests/contract/test_openapi_contract.py`](../tests/contract/test_openapi_contract.py) | Prueba de corte vertical (API + Hexagonal) en verde, contra el historial real de inventario ([`docs/propiedad-datos.md`](propiedad-datos.md), [`docs/auditoria-modularidad.md`](auditoria-modularidad.md)); contrato de API validado en CI (ADR-0004) |
| ASP-02 | [Control de Concurrencia e Inventario (Reto Corte 1)](#asp-02--control-de-concurrencia-e-inventario-reto-corte-1) | [ESC-01](arc42/arc42-template-EN.md#quality-scenarios) — Latencia $p95 \le 400\text{ ms}$ con 20 usuarios | [C4 Nivel 2](c4/containers.md), [C4 Nivel 3](c4/components.md), [Mapa de contextos](context-map.md), [Contrato OpenAPI](../contracts/openapi/v1.json) — módulos `inventario` y `productos` | [ADR-0002](adr/0002-control-concurrencia-memoria-inventario.md) — Control de concurrencia en memoria para inventario; [ADR-0004](adr/0004-contrato-api-versionado-openapi.md) documenta el `503` de degradación en el contrato | [`app/inventario/`](../app/inventario/) — Gestión de movimientos y stock atómico | [`tests/inventario/test_concurrencia.py`](../tests/inventario/test_concurrencia.py), [`tests/contract/test_openapi_contract.py`](../tests/contract/test_openapi_contract.py) | [`docs/retos/corte-1-medicion.md`](retos/corte-1-medicion.md) — Reporte de medición con $p95 = 28\text{ ms}$ |

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

### C4: dónde vive este aspecto

El [diagrama de contenedores (C4 Nivel 2)](c4/containers.md) y el [diagrama de contexto (C4 Nivel 1)](c4/context.md) muestran que este aspecto vive en la capa de Backend (`API Backend (Monolito Modular)`), la cual expone las reglas de negocio hacia la interfaz. En la estructura del código, se implementó como corte vertical en los módulos [`app/productos/`](../app/productos/) e [`app/inventario/`](../app/inventario/), desacoplados mediante puertos y adaptadores según el [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md). El [C4 Nivel 3](c4/components.md) abre esos dos módulos hasta el nivel de componente, y el [mapa de contextos](context-map.md) documenta la relación cliente-proveedor entre ambos, tipificada según el [ADR-0003](adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion.md).

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
- **Línea Base Verificable:** La ejecución previa sin control de concurrencia permitía escrituras sucias (*dirty writes*). El escenario de calidad fijó el umbral en ráfagas de 20 peticiones concurrentes con $p95 \le 400\text{ ms}$ y 0 descuadres.

---

### Por qué se eligió este aspecto

Atiende directamente la restricción asignada para el **Corte 1**. Demuestra cómo la arquitectura monolítica modular soporta aislamiento transaccional a nivel de aplicación sin comprometer los tiempos de respuesta exigidos por los escenarios de calidad del sistema.

---

### Requisito: escenario de calidad

- **ESC-01 (Rendimiento y Concurrencia):** 20 peticiones simultáneas reduciendo inventario sobre el mismo SKU.
- **Umbral de Aceptación:** Latencia $p95 \le 400\text{ ms}$ y stock final resultante exacto (cero inconsistencias o descuadres).

---

### C4: dónde vive este aspecto

Vive en la interacción entre los módulos `app/inventario/` y `app/productos/` dentro del contenedor de la **API Backend (FastAPI)** [C4 Nivel 2](c4/containers.md).

---

### ADR: decisiones aplicadas

El [ADR-0002](adr/0002-control-concurrencia-memoria-inventario.md) establece el mecanismo de **exclusión mutua (Mutex/Lock asíncrono) por SKU** en la capa de aplicación/dominio, evitando condiciones de carrera en memoria.

---

### Degradación Controlada y Resiliencia

En caso de que la carga supere la capacidad de atención o el tiempo de espera por el cerrojo asíncrono exceda el límite razonable:
- El sistema encola ordenadamente las peticiones sobre el *event loop* de FastAPI sin bloquear el hilo principal.
- Ante saturación extrema o timeouts de espera sobre el lock, el servicio responde con estados HTTP controlados (`429 Too Many Requests` o `503 Service Unavailable`), protegiendo la consistencia del inventario y evitando el colapso del proceso.

---

### Código, Pruebas y Evidencia

- **Código:** Módulos de [`app/inventario/`](../app/inventario/) y [`app/productos/`](../app/productos/).
- **Prueba Automatizada:** [`tests/inventario/test_concurrencia.py`](../tests/inventario/test_concurrencia.py) (simula 20 llamadas asíncronas concurrentes).
- **Evidencia Medida:** Reporte en [`docs/retos/corte-1-medicion.md`](retos/corte-1-medicion.md) que acredita $p95 = 28\text{ ms}$ bajo carga (superando ampliamente el umbral exigido de $400\text{ ms}$).

---

### Estado

- [x] Aspecto de concurrencia e inventario declarado
- [x] Diagnóstico técnico detallado (Síntoma, Causa Raíz, Riesgo, Línea Base)
- [x] Escenario de rendimiento verificado (ESC-01)
- [x] Decisiones de arquitectura registradas en ADR-0002
- [x] Módulo `app/inventario/` integrado a la trazabilidad
- [x] Estrategia de degradación controlada documentada
- [x] Prueba automatizada de 20 peticiones concurrentes en verde
- [x] Reporte de medición reproducible publicado en la documentación