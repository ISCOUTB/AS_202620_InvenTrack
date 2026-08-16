# InvenTrack — Sistema Inteligente de Inventarios

Proyecto del curso **Arquitectura de Software** (AS_202620) — Universidad Tecnológica de
Bolívar.
Repositorio técnico: `AS_202620_InvenTrack` (organización ISCOUTB).

## Descripción

Sistema de gestión de inventarios dirigido a pequeñas y medianas empresas que hoy
gestionan su stock mediante Excel o registros manuales. Centraliza productos,
proveedores, entradas, salidas, usuarios y movimientos, con alertas de stock bajo.

Ver el planteamiento completo del problema en [`docs/ficha_problema.md`](docs/ficha_problema.md).

## Equipo de desarrollo

- Esteban Peluffo
- Felix Taborda
- Jose Vargas
- Javier Carta

## Aspecto de calidad declarado

**Consistencia de datos** — el sistema debe garantizar que movimientos de inventario
registrados por distintos usuarios de forma simultánea no generen datos inconsistentes
(stock negativo, doble descuento del mismo movimiento). Ver detalle, justificación y
escenarios de calidad en [`docs/aspectos.md`](docs/aspectos.md).

## Documentación de arquitectura

La documentación sigue la plantilla **arc42** en
[`docs/arc42/arc42-template-EN.md`](docs/arc42/arc42-template-EN.md). Hasta la fecha
incluye:

- **Introduction and Goals** — objetivos, atributos de calidad priorizados, stakeholders.
- **Architecture Constraints** — restricciones técnicas, legales y organizativas justificadas.
- **Context and Scope** — contexto de negocio y técnico del sistema.
- **Quality Requirements** — árbol de utilidad, 5 escenarios de calidad de seis partes, y trade-offs identificados.

### Diagramas C4

- [Nivel 1 — Contexto](docs/c4/context.md): actores, el sistema y el único sistema externo (notificaciones).
- [Árbol de utilidad](docs/c4/utility-tree.md): priorización de atributos de calidad por impacto de negocio y riesgo técnico.

### Decisiones de arquitectura (ADR)

Las decisiones arquitectónicas se documentan como archivos individuales en
[`docs/adr/`](docs/adr/) siguiendo el modelo de trazabilidad Aspecto → Requisito → C4 →
ADR → Código → Pruebas → Evidencia. Aún no hay decisiones registradas.

## Estructura del repositorio

```
docs/
├── arc42/
│   ├── arc42-template-EN.md   # Documentación arc42 (secciones 1-3 y 10)
│   └── images/
│       └── arc42-logo.png
├── c4/
│   ├── context.md              # C4 Nivel 1 — Diagrama de contexto
│   └── utility-tree.md         # Árbol de utilidad
├── adr/
│   └── README.md                # Architecture Decision Records (pendiente)
├── ficha_problema.md            # Planteamiento del problema (1 página)
├── aspectos.md                  # Aspecto de calidad declarado + escenarios enlazados
└── ia.md                        # Registro de uso de IA en el proyecto
```

## Progreso por semana

| Semana | Evidencia | Estado |
|---|---|---|
| S1 | Equipo, problema y repositorio | ✅ Completo |
| S2 | Escenarios de calidad y restricciones | ✅ Completo |

## Uso de IA

Este proyecto documenta el uso de herramientas de IA de forma transparente en
[`docs/ia.md`](docs/ia.md), como parte de los requisitos del curso.
