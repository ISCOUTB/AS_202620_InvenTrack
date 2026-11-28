# Índice Trazable de Correcciones — InvenTrack

Este documento consolida los hallazgos reportados en las evaluaciones automáticas/docentes (S1 a S10), la contrastación de evidencia con la fecha de cierre de cada commit y la trazabilidad de sus correcciones.

---

## 1. Criterios de Auditoría y Verificación de Feedback

> **Criterio Utilizado:** Se evalúa el estado del repositorio según el hash calificado en cada fecha de cierre. Las discrepancias encontradas entre la revisión automática y los artefactos reales se documentan a continuación para garantizar la trazabilidad del Reto Corte 1.

---

## 2. Matriz Trazable de Hallazgos y Correcciones

| ID Hallazgo | Entrega Orig. | Descripción del Hallazgo / Observación | Análisis / Acción Correctiva Aplicada | Ruta del Artefacto / Commit / Run | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **HAL-01** | S1 / S2 | Formato de aspectos de calidad en prosa y columnas incompletas. | Reestructurado a la tabla de 8 columnas navegable (`ID -> Aspecto -> Requisito -> C4 -> ADR -> Código -> Pruebas -> Evidencia`). | [`docs/aspectos.md`](./docs/aspectos.md) | **Corregido** |
| **HAL-02** | S3 | ADR-0001 en estado propuesto. | Ratificado ADR-0001 como **Aceptado** con justificación explícita de la arquitectura de monolito modular. | [`docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md`](./docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md) | **Corregido** |
| **HAL-03** | S4 | Reporte de secciones §4, §5, §6 y §9 de arc42 como no realizadas. | **Aclaración / Discrepancia:** Las secciones sí existían en `arc42-template-EN.md` previo al cierre. Se unificó toda la documentación bajo la ruta estándar de arc42. | [`docs/arc42/`](./docs/arc42/) | **Corregido** |
| **HAL-04** | S4 | Observación sobre C4 Nivel 2 (Frontend y BD no implementados). | **Aclaración:** C4 Nivel 2 documentaba la arquitectura objetivo, marcando explícitamente contenedores como "Por definir". Se refinó para mostrar el estado implementado actual. | [`docs/c4/containers.md`](./docs/c4/containers.md) | **Corregido** |
| **HAL-05** | S5 | Formato de `correcciones.md` redactado en prosa sin matriz estructurada. | Transformado en este índice trazable formal de 6 columnas exigido por la rúbrica. | [`correcciones.md`](./correcciones.md) | **Corregido** |
| **HAL-06** | S6 | Ausencia de mapa de contextos y definición de propiedad de datos. | Creados `context-map.md` y `propiedad-datos.md` delimitando Single Ownership y canales entre módulos. | [`docs/context-map.md`](./docs/context-map.md), [`docs/propiedad-datos.md`](./docs/propiedad-datos.md) | **Corregido** |
| **HAL-07** | S6 | Violación de fronteras de dominio en verificación de movimientos (`in_memory_verificador_movimientos.py`). | Resuelto mediante la implementación de puertos de aplicación e inversión de dependencias cruzada (`ADR-0003`). Documentado en auditoría. | [`docs/adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion`](./docs/adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion.md), [`docs/auditoria-modularidad.md`](./docs/auditoria-modularidad.md) | **Corregido** |
| **HAL-08** | S6 | C4 Nivel 3 (Componentes) marcado como pendiente. | Diseñado e integrado el diagrama de componentes internos de la API Backend en Mermaid. | [`docs/c4/components.md`](./docs/c4/components.md) | **Corregido** |
| **HAL-09** | S9 / S10 | La medición de p95 ejercitaba `/health` y no el flujo de negocio declarado; la línea base anterior no era reproducible. | La prueba de concurrencia mide 20 `POST /inventario/{sku}/salidas` reales, calcula p95 y exige `<= 400 ms`. La cifra histórica de 28 ms se conserva solo como referencia no reproducible; no se inventa una línea base ausente. | [`tests/inventario/test_concurrencia.py`](./tests/inventario/test_concurrencia.py), [`docs/retos/corte-2-experimento.md`](./docs/retos/corte-2-experimento.md), [`docs/evidencia-ia-corte-s9.md`](./docs/evidencia-ia-corte-s9.md) | **Flujo de medición corregido. Línea base previa al bloqueo sin evidencia reproducible.** Las [mediciones comparables de S10 y S16](docs/verificacion-final.md#concurrencia-y-recuperación) corresponden a revisiones posteriores. |
| **HAL-10** | S10 | Cantidades `0` o negativas podían alcanzar el dominio y producir un error no contractual. | Validación `cantidad > 0` en el esquema HTTP, contrato OpenAPI actualizado y pruebas negativas para entradas y salidas. | [`app/inventario/infrastructure/router.py`](./app/inventario/infrastructure/router.py), [`contracts/openapi/v1.json`](./contracts/openapi/v1.json), [`tests/inventario/test_inventario.py`](./tests/inventario/test_inventario.py) | **Corregido** |
| **HAL-11** | S12 / S15 | Observación sobre modificaciones post-creación en ADR-0012 y ADR-0016. | **Aclaración factual:** Los commits `ab80c28` (ADR-0012) y `1269ffb` (ADR-0016) corresponden a la misma jornada de trabajo del 25/octubre para ratificar estado ("Pendiente" a "Aceptado") y detallar observabilidad/deduplicación, sin introducir divergencia o revocación de decisiones arquitectónicas previas. | [`docs/adr/0012-mantener-repositorios-en-memoria-en-el-mvp.md`](docs/adr/0012-mantener-repositorios-en-memoria-en-el-mvp.md), [`docs/adr/0016-integrar-eventos-de-auditoria-en-movimientos.md`](docs/adr/0016-integrar-eventos-de-auditoria-en-movimientos.md) | **Aclarado** |

## Seguimiento posterior a S15

| Hallazgo | Cambio | Evidencia |
|---|---|---|
| S13 · Frontera operativa sin decisión propia | ADR-0018 ratifica el token operativo y ADR-0019 formaliza identidad por usuario. | [ADR-0018](docs/adr/0018-restringir-superficies-internas-en-produccion.md), [ADR-0019](docs/adr/0019-autenticar-usuarios-y-autorizar-por-rol.md) |
| S14 · Carga distinta a §10 | Se conservó el reto anterior y se midieron ambos escenarios literales. | [Ensayo y muestras](docs/verificacion-final.md) |
| Final · Recuperación, actor y gate público | Perfil SQLite con restauración e identidad. Resultados de Sonar por revisión y disponibilidad remota registrados por separado. | [ADR-0020](docs/adr/0020-persistir-inventario-y-auditoria-en-sqlite.md), [verificación](docs/verificacion-final.md) |
| S16 · Una corrida de 20 ventas en SQLite superaba los 400 ms | Serializar las escrituras de la instancia y reutilizar la conexión. Las tres corridas del candidato terminaron con saldo 80 y p95 entre 98,089 y 102,243 ms. | [ADR-0021](docs/adr/0021-serializar-escrituras-sqlite.md), [comparación con S10 y muestras](docs/verificacion-final.md#concurrencia-y-recuperación) |

## Retroalimentación del cierre

La referencia de partida es el commit `51f353704cabdd0100c082d6af3912d18dc83795` de `main`. El equipo indicó que el formulario del jurado no fue compartido. La lista de recomendaciones de los pares de S14 y el número total de recomendaciones recibidas siguen sin confirmar. Las observaciones técnicas públicas y la solicitud del equipo tienen su propio origen en la tabla.
