# Índice Trazable de Correcciones — InvenTrack

Este documento consolida los hallazgos reportados en las evaluaciones automáticas/docentes (S1 a S6), la contrastación de evidencia con la fecha de cierre de cada commit y la trazabilidad de sus correcciones.

---

## 1. Criterios de Auditoría y Verificación de Feedback

> **Criterio Utilizado:** Se evalúa el estado del repositorio según el hash calificado en cada fecha de cierre. Las discrepancias encontradas entre la revisión automática y los artefactos reales se documentan a continuación para garantizar la trazabilidad del Reto Corte 1.

---

## 2. Matriz Trazable de Hallazgos y Correcciones

| ID Hallazgo | Entrega Orig. | Descripción del Hallazgo / Observación | Análisis / Acción Correctiva Aplicada | Ruta del Artefacto / Commit / Run | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **HAL-01** | S1 / S2 | Formato de aspectos de calidad en prosa y columnas incompletas[cite: 1]. | Reestructurado a la tabla de 8 columnas navegable (`ID -> Aspecto -> Requisito -> C4 -> ADR -> Código -> Pruebas -> Evidencia`). | `docs/aspectos.md` | **Corregido** |
| **HAL-02** | S3 | ADR-0001 en estado propuesto[cite: 1]. | Ratificado ADR-0001 como **Aceptado** con justificación explícita de la arquitectura de monolito modular. | `docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md` | **Corregido** |
| **HAL-03** | S4 | Reporte de secciones §4, §5, §6 y §9 de arc42 como no realizadas[cite: 1]. | **Aclaración / Discrepancia:** Las secciones sí existían en `arc42-template-EN.md` previo al cierre[cite: 1]. Se unificó toda la documentación bajo la ruta estándar de arc42 en español[cite: 1, 2]. | `docs/arc42/` | **Corregido** |
| **HAL-04** | S4 | Observación sobre C4 Nivel 2 (Frontend y BD no implementados)[cite: 1]. | **Aclaración:** C4 Nivel 2 documentaba la arquitectura objetivo, marcando explícitamente contenedores como "Por definir"[cite: 1]. Se refinó para mostrar el estado implementado actual[cite: 1, 2]. | `docs/c4/container.md` | **Corregido** |
| **HAL-05** | S5 | Formato de `correcciones.md` redactado en prosa sin matriz estructurada[cite: 1, 2]. | Transformado en este índice trazable formal de 6 columnas exigido por la rúbrica[cite: 1, 2]. | `correcciones.md` | **Corregido** |
| **HAL-06** | S6 | Ausencia de mapa de contextos y definición de propiedad de datos[cite: 2]. | Creados `context-map.md` y `propiedad-datos.md` delimitando Single Ownership y canales entre módulos[cite: 2]. | `docs/context-map.md`, `docs/propiedad-datos.md` | **Corregido** |
| **HAL-07** | S6 | Violación de fronteras de dominio en verificación de movimientos (`in_memory_verificador_movimientos.py`)[cite: 2]. | Resuelto mediante la implementación de puertos de aplicación e inversión de dependencias cruzada (`ADR-0003`)[cite: 2]. Documentado en auditoría[cite: 2]. | `docs/adr/0003-*.md`, `docs/auditoria-modularidad.md` | **Corregido** |
| **HAL-08** | S6 | C4 Nivel 3 (Componentes) marcado como pendiente[cite: 1, 2]. | Diseñado e integrado el diagrama de componentes internos de la API Backend en Mermaid[cite: 1, 2]. | `docs/c4/components.md` | **Corregido** |