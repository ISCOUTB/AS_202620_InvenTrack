# Índice Trazable de Correcciones — InvenTrack

Este documento consolida los hallazgos reportados en las evaluaciones automáticas/docentes (S1 a S6), la contrastación de evidencia con la fecha de cierre de cada commit y la trazabilidad de sus correcciones.

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