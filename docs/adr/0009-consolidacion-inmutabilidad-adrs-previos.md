# ADR-0009: Consolidación de inmutabilidad en decisiones previas (2, 4 y 5)

- **Estado:** Aceptado
- **Fecha:** 2026-10-04
- **Decisores:** Equipo InvenTrack

## Contexto
Durante ciclos anteriores, los ADR-0002, ADR-0004 y ADR-0005 sufrieron ediciones posteriores a su estado de "Aceptado" (ej. adición de detalles de Swagger, ajustes en el lock de concurrencia y despliegue en Render) sin registrar un nuevo ADR que los reemplazara o complementara. 

## Decisión
Se formaliza que el contenido actual de los ADR-0002, ADR-0004 y ADR-0005 representa la decisión final consolidada. A partir de este punto, se decreta la inmutabilidad estricta de cualquier ADR en estado "Aceptado". Cualquier modificación arquitectónica futura requerirá obligatoriamente la creación de un nuevo ADR que reemplace o complemente al anterior.

## Consecuencias
- El historial de decisiones arquitectónicas recupera su integridad.
- Queda prohibida la edición técnica de ADRs 1 al 8.