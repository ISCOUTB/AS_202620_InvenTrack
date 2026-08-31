<div align="center">

# InvenTrack — Sistema Inteligente de Inventarios

**Curso:** Arquitectura de Software (AS_202620) · Universidad Tecnológica de Bolívar  
**Repositorio:** `AS_202620_InvenTrack` · Organización [ISCOUTB](https://github.com/ISCOUTB)

</div>

---

## Tabla de contenidos

- [Navegación rápida](#navegación-rápida)
- [Descripción](#descripción)
- [Equipo de desarrollo](#equipo-de-desarrollo)
- [Aspecto de calidad declarado](#aspecto-de-calidad-declarado)
- [Cómo está organizado este repositorio](#cómo-está-organizado-este-repositorio)
- [Documentación de arquitectura](#documentación-de-arquitectura)
- [Matriz comparativa de estilos](#matriz-comparativa-de-estilos)
- [Diagramas C4](#diagramas-c4)
- [Decisiones de arquitectura (ADR)](#decisiones-de-arquitectura-adr)
- [Stack tecnológico](#stack-tecnológico)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Cómo ejecutar el esqueleto](#cómo-ejecutar-el-esqueleto)
- [Flujo de trabajo del equipo](#flujo-de-trabajo-del-equipo)
- [Progreso por semana](#progreso-por-semana)
- [Uso de IA](#uso-de-ia)
- [Licencia y uso académico](#licencia-y-uso-académico)
- [Contacto](#contacto)

---

## Navegación rápida

| Documento | Contenido |
|---|---|
| [Ficha del problema](docs/ficha_problema.md) | Problema, solución propuesta, alcance del MVP y usuarios objetivo |
| [Aspecto de calidad declarado](docs/aspectos.md) | Consistencia de datos: descripción, justificación, escenarios y estado |
| [Documentación arc42](docs/arc42/arc42-template-EN.md) | Objetivos, stakeholders, restricciones, contexto, estrategia, vistas y calidad |
| [C4 — Nivel 1 (Contexto)](docs/c4/context.md) | Diagrama de contexto: actores, sistema y sistema externo |
| [C4 — Nivel 2 (Contenedores)](docs/c4/container.md) | Diagrama de contenedores: frontend, API backend, DB y notificaciones |
| [Árbol de utilidad](docs/utility-tree.md) | Priorización de atributos de calidad por impacto y riesgo |
| [ADR-0001](docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md) | Registro de decisión: Monolito modular con hexagonal por módulo (Aceptado) |
| [Uso de IA](docs/ia.md) | Registro transparente del uso de IA en el proyecto |

---

## Descripción

Sistema de gestión de inventarios dirigido a pequeñas y medianas empresas que hoy gestionan su stock mediante Excel o registros manuales. Centraliza productos, proveedores, entradas, salidas, usuarios y movimientos, con alertas automáticas de stock bajo.

Resuelve problemas concretos de las PYMEs objetivo: descuadres de stock, quiebres no detectados a tiempo, compras mal planificadas por falta de datos históricos, ausencia de trazabilidad, y dependencia de una sola persona como punto único de fallo operativo. Ver el planteamiento completo en [`docs/ficha_problema.md`](docs/ficha_problema.md).

## Equipo de desarrollo

| Integrante | Rol en el proyecto |
|---|---|
| Esteban Peluffo | Equipo de desarrollo |
| Felix Taborda | Equipo de desarrollo |
| Jose Vargas | Equipo de desarrollo |
| Javier Carta | Equipo de desarrollo |

## Aspecto de calidad declarado

**Consistencia de datos** — el sistema debe garantizar que movimientos de inventario registrados por distintos usuarios de forma simultánea no generen datos inconsistentes (stock negativo, doble descuento del mismo movimiento). Un inventario con cifras incorrectas es peor que uno manual, porque genera falsa confianza en la toma de decisiones: el dueño dejaría de verificar a mano justo lo que el sistema ya le está diciendo (incorrectamente) que está bien.

Ver detalle, justificación y escenarios de calidad en [`docs/aspectos.md`](docs/aspectos.md).

## Cómo está organizado este repositorio

Antes de entrar a cada carpeta, vale la pena explicar la lógica detrás de la estructura, porque no es arbitraria — cada carpeta tiene un solo trabajo y nada se repite entre ellas:

- **`docs/arc42/`** cuenta la historia completa en texto: objetivos, restricciones, contexto, estrategia de solución, vista de bloques, vista de ejecución, atributos de calidad y los escenarios que los hacen medibles. Es el documento que se lee de principio a fin para entender las decisiones de calidad del proyecto.
- **`docs/c4/`** y **`docs/utility-tree.md`** son los diagramas — representaciones visuales que se enlazan desde el arc42 en vez de repetirse ahí. El arc42 explica *por qué*; los diagramas muestran *cómo se ve*.
- **`docs/adr/`** registra las decisiones arquitectónicas concretas, una por archivo, a medida que el equipo las va ratificando (por ejemplo, la elección del Monolito Modular en el ADR-0001 o el mecanismo de consistencia en movimientos concurrentes).
- **`docs/aspectos.md`** es el índice que conecta todo lo anterior: por cada aspecto de calidad declarado, enlaza su requisito, su C4, su ADR, su código y sus pruebas, siguiendo el modelo `Aspecto → Requisito → C4 → ADR → Código → Pruebas → Evidencia` visto en clase.

Esta separación responde directamente a la estructura que pide el curso (`/docs/arc42`, `/docs/adr`, `/docs/c4`), y evita que el mismo contenido quede duplicado en dos lugares distintos del repositorio.

## Documentación de arquitectura

La documentación sigue la plantilla **arc42**, disponible completa en [`docs/arc42/arc42-template-EN.md`](docs/arc42/arc42-template-EN.md). Incluye:

| Sección arc42 | Contenido |
|---|---|
| 1 · Introduction and Goals | Objetivos del sistema, atributos de calidad priorizados (marco "cinco atributos, cinco preguntas"), stakeholders clasificados por perspectiva (Usuario y negocio / Operaciones y seguridad) |
| 2 · Architecture Constraints | 7 restricciones técnicas, legales y organizativas, cada una con su justificación y quién la impone |
| 3 · Context and Scope | Contexto de negocio (actores que interactúan con el sistema) y contexto técnico (canales y protocolos) |
| 4 · Solution Strategy | Resumen fundamental de las decisiones clave de arquitectura (Monolito Modular, Hexagonal por módulo, desacoplamiento de framework) |
| 5 · Building Block View | Descomposición en subsistemas y módulos internos (Productos, Inventario, Proveedores, Usuarios, Alertas) |
| 6 · Runtime View | Diagramas de secuencia para los flujos críticos (ej. Registro de Movimiento de Inventario) |
| 9 · Architecture Decisions | Enlace y matriz de trazabilidad con los Registros de Decisiones de Arquitectura (ADRs) |
| 10 · Quality Requirements | Árbol de utilidad, 5 escenarios de calidad de seis partes cada uno (Fuente, Estímulo, Artefacto, Entorno, Respuesta, Medida), y trade-offs identificados entre atributos |
| 12 · Glossary | Glosario de términos de dominio técnico y de negocio (Stock, Quiebre, SKU, Ajuste, etc.) |

Las demás secciones de arc42 (Deployment View, Cross-cutting Concepts, Risks) se continuarán detallando en semanas posteriores conforme se definan las decisiones de infraestructura y persistencia final.

## Matriz comparativa de estilos

La comparación entre arquitectura por capas, hexagonal y monolito modular está en [`docs/matriz-comparativa-estilos.md`](docs/matriz-comparativa-estilos.md). La decisión adoptada combina un **Monolito Modular** como estructura general con **Hexagonal por módulo**.

## Diagramas C4

- **[Nivel 1 — Contexto](docs/c4/context.md):** actores del sistema, InvenTrack, y el único sistema externo (servicio de notificaciones). Incluye la explicación de por qué cada actor está ahí y por qué el Proveedor, aunque es un interesado real, no aparece como actor externo en este nivel.
- **[Nivel 2 — Contenedores](docs/c4/container.md):** desglose de los contenedores ejecutables (Frontend Web/Móvil, API Backend FastAPI, Base de Datos PostgreSQL/SQLite y Servicio de Notificaciones), detallando protocolos de comunicación y límites tecnológicos.
- **[Árbol de utilidad](docs/utility-tree.md):** priorización de los cinco escenarios de calidad por impacto de negocio y riesgo técnico, coloreada por prioridad, con una tabla que explica el razonamiento detrás de cada nivel de prioridad.

Todos los diagramas están escritos en Mermaid y se renderizan directamente al abrir el archivo en GitHub.

## Decisiones de arquitectura (ADR)

Las decisiones arquitectónicas se documentan como archivos individuales en [`docs/adr/`](docs/adr/), siguiendo el modelo de trazabilidad visto en clase:

```text
Aspecto → Requisito → C4 → ADR → Código → Pruebas → Evidencia
```

La decisión de estilo arquitectónico está registrada en el
[ADR-0001](docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md). Sigue pendiente el mecanismo de
control de concurrencia para el aspecto "Consistencia de datos" (ver escenarios ESC-01 y
ESC-02, y la sección de trade-offs en el arc42): las alternativas sobre la mesa son
transacciones con aislamiento adecuado, bloqueo pesimista, bloqueo optimista, o
validaciones a nivel de base de datos — cada una con distinto costo en Rendimiento.

## Stack tecnológico

El backend del esqueleto usa **FastAPI** con **Uvicorn**. La base de datos, el
frontend y el hosting quedan pendientes de decisión formal, respetando la
restricción de usar tecnología open source o con capa gratuita.

| Capa | Tecnología | Estado |
|---|---|---|
| Frontend | Por definir | Pendiente |
| Backend | FastAPI + Uvicorn | Esqueleto ejecutable |
| Base de datos | Por definir | Pendiente |
| Hosting / despliegue | Por definir | Pendiente (ver encuesta de disponibilidad técnica) |
| CI / calidad de código | SonarCloud | Definido por el curso |

## Estructura del repositorio

```
.github/
└── workflows/
    └── test.yml                 # Pipeline de CI/CD para pruebas en GitHub Actions
docs/
├── arc42/
│   ├── arc42-template-EN.md    # Narrativa completa (secciones 1-4 y 10)
│   └── images/
│       └── arc42-logo.png
├── c4/
│   └── context.md              # C4 Nivel 1 — Diagrama de contexto
├── adr/
│   └── 0001-usar-monolito-modular-con-hexagonal-por-modulo.md
├── ficha_problema.md            # Planteamiento del problema (1 página)
├── aspectos.md                  # Índice: aspecto declared + escenarios enlazados
├── matriz-comparativa-estilos.md# Comparativa de estilos arquitectónicos
├── utility-tree.md              # Árbol de utilidad (diagrama + explicación)
└── ia.md                        # Registro de uso de IA en el proyecto
app/                             # Esqueleto FastAPI del monolito modular
├── main.py                      # Composición de la aplicación
├── shared/                      # Código compartido
├── productos/                   # Módulo de productos
├── proveedores/                 # Módulo de proveedores
├── inventario/                  # Módulo de inventario
├── usuarios/                    # Módulo de usuarios
└── alertas/                     # Módulo de alertas
tests/                           # Prueba automatizada del esqueleto
└── test_health.py
requirements.txt                 # Dependencias del esqueleto
```

## Cómo ejecutar el esqueleto

Requisito: Python 3.11 o superior.

```powershell
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

La aplicación queda disponible en `http://127.0.0.1:8000` y expone `GET /health`.
La prueba automatizada se ejecuta con:

```powershell
python -m pytest -v
```

## Flujo de trabajo del equipo

- Los cambios se suben directo a `main` mientras el proyecto está en fase de
  documentación (semanas 1-2 del curso). Si el equipo lo prefiere, se puede migrar a un
  flujo con ramas y pull requests una vez comience la implementación de código.
- Cada entrega semanal se corresponde con un commit o grupo de commits identificable,
  para mantener trazabilidad de qué se agregó en cada evidencia.
- Antes de subir un documento nuevo, revisar que los enlaces internos (`docs/...`) usen
  rutas relativas correctas según la carpeta donde vive cada archivo — un archivo dentro
  de `docs/arc42/` necesita `../` para referenciar algo en `docs/`, mientras que un
  archivo directo en `docs/` no.

## Progreso por semana

| Semana | Evidencia | Estado |
|---|---|---|
| S1 | Equipo, problema y repositorio | Completo |
| S2 | Escenarios de calidad y restricciones | Completo |
| S3 | Estrategia, matriz, ADR y esqueleto ejecutable | Completo |
| S4 | Vista de Contenedores (C4 N2), Secciones arc42 (4, 5, 6, 9, 12) y Corte Vertical |  Completo |

## Uso de IA

Este proyecto documenta el uso de herramientas de IA de forma transparente en
[`docs/ia.md`](docs/ia.md), incluyendo qué herramientas se usaron, en qué etapa, y qué
tanto se apoyó el equipo en ellas frente a sus propias decisiones — incluyendo los casos
en que el equipo corrigió el contenido generado por IA contra el material del curso —
como parte de los requisitos del curso.

## Licencia y uso académico

Este repositorio es un proyecto académico desarrollado para el curso Arquitectura de
Software (AS_202620) de la Universidad Tecnológica de Bolívar. Su contenido está sujeto a
la política de uso responsable de IA y a las rúbricas del curso, disponibles en la sección
"Inicio y orientación" de Savio.

## Contacto

**Docente:** Jairo Serrano — jserrano@utb.edu.co

---

<div align="center">

Programa de Ingeniería de Sistemas y Computación · Universidad Tecnológica de Bolívar

</div>
