<div align="center">

# InvenTrack — Sistema Inteligente de Inventarios

**Curso:** Arquitectura de Software (AS_202620) · Universidad Tecnológica de Bolívar  
**Repositorio:** `AS_202620_InvenTrack` · Organización [ISCOUTB](https://github.com/ISCOUTB)

</div>

---

## 🚀 Estado del Proyecto — Reto Corte 1 (AS_202620)

* **Estilo Arquitectónico:** Monolito Modular con Arquitectura Hexagonal por Módulo ([ADR-0001](docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md)).
* **Mecanismo de Concurrencia:** Exclusión mutua asíncrona por SKU (`asyncio.Lock()`) ([ADR-0002](docs/adr/0002-control-concurrencia-memoria-inventario.md)).
* **Resultados de Medición:** **$p95 = 28\text{ ms}$** bajo ráfagas de 20 peticiones simultáneas sobre el mismo SKU (Umbral exigido: $\le 400\text{ ms}$) ([Reporte de Medición](docs/retos/corte-1-medicion.md)).
* **Matriz de Trazabilidad:** Cadena navegable `Aspecto → Requisito → C4 → ADR → Código → Pruebas → Evidencia` ([Aspectos de Calidad](docs/aspectos.md)).
* **Transparencia en Uso de IA:** Prompts, decisiones aceptadas, correcciones y rechazos por criterio técnico ([Registro de IA](docs/ia.md)).

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
- [Análisis estático](#análisis-estático)
- [Licencia y uso académico](#licencia-y-uso-académico)
- [Contacto](#contacto)

---

## Navegación rápida

| Documento | Contenido |
|---|---|
| [Ficha del problema](docs/ficha_problema.md) | Problema, solución propuesta, alcance del MVP y usuarios objetivo |
| [Aspecto de calidad declarado](docs/aspectos.md) | Consistencia de datos: descripción, diagnóstico, escenarios y trazabilidad |
| [Documentación arc42](docs/arc42/arc42-template-EN.md) | Objetivos, stakeholders, restricciones, contexto, estrategia, vistas y calidad |
| [C4 — Nivel 1 (Contexto)](docs/c4/context.md) | Diagrama de contexto: actores, sistema y sistema externo |
| [C4 — Nivel 2 (Contenedores)](docs/c4/containers.md) | Diagrama de contenedores, evolución post-reto y aislamiento en memoria |
| [Árbol de utilidad](docs/utility-tree.md) | Priorización de atributos de calidad por impacto y riesgo |
| [ADR-0001](docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md) | Registro de decisión: Monolito modular con hexagonal por módulo (Aceptado) |
| [ADR-0002](docs/adr/0002-control-concurrencia-memoria-inventario.md) | Control de concurrencia en memoria, criterios de revisión y costo de reversión (Aceptado) |
| [Medición Reto Corte 1](docs/retos/corte-1-medicion.md) | Diagnóstico, pruebas de concurrencia, degradación controlada y comando de reproducción |
| [Uso de IA](docs/ia.md) | Registro transparente de IA (sugerencias aceptadas vs. rechazadas)|

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

**Consistencia de datos** — el sistema debe garantizar que movimientos de inventario registrados por distintos usuarios de forma simultánea no generen datos inconsistentes (stock negativo, doble descuento del mismo movimiento). Un inventario con cifras incorrectas es peor que uno manual, porque genera falsa confianza en la toma de decisiones.

Ver detalle, justificación, escenarios de calidad y matriz de trazabilidad del Reto en [`docs/aspectos.md`](docs/aspectos.md).

## Cómo está organizado este repositorio

Antes de entrar a cada carpeta, vale la pena explicar la lógica detrás de la estructura:

- **`docs/arc42/`** cuenta la historia completa en texto: objetivos, restricciones, contexto, estrategia de solución, vista de bloques, vista de ejecución, atributos de calidad, conceptos transversales y los escenarios que los hacen medibles.
- **`docs/c4/`** y **`docs/utility-tree.md`** son los diagramas — representaciones visuales que se enlazan desde el arc42.
- **`docs/adr/`** registra las decisiones arquitectónicas concretas, una por archivo (ADR-0001 para el estilo general y ADR-0002 para el control de concurrencia).
- **`docs/retos/`** documenta el diagnóstico, carga simulada, comandos de reproducción y resultados del reto del Corte 1.
- **`docs/aspectos.md`** es el índice que conecta todo siguiendo la cadena navegable: `Aspecto → Requisito → C4 → ADR → Código → Pruebas → Evidencia`.

## Documentación de arquitectura

La documentación sigue la plantilla **arc42**, disponible completa en [`docs/arc42/arc42-template-EN.md`](docs/arc42/arc42-template-EN.md). Incluye:

| Sección arc42 | Contenido |
|---|---|
| 1 · Introduction and Goals | Objetivos del sistema, atributos de calidad priorizados y stakeholders |
| 2 · Architecture Constraints | Restricciones técnicas, legales y organizativas |
| 3 · Context and Scope | Contexto de negocio y contexto técnico |
| 4 · Solution Strategy | Decisiones clave (Monolito Modular, Hexagonal por módulo, desacoplamiento) |
| 5 · Building Block View | Descomposición en subsistemas y módulos internos (Productos, Inventario, Proveedores, etc.) |
| 6 · Runtime View | Diagramas de secuencia para flujos críticos (ej. Registro concurrente de movimientos) |
| 7 · Deployment View | Despliegue inicial como una única aplicación InvenTrack (FastAPI + Uvicorn) ejecutada localmente |
| 8 · Cross-cutting Concepts | Mecanismo de exclusión mutua asíncrona por SKU y manejo unificado de excepciones |
| 9 · Architecture Decisions | Enlace y matriz de trazabilidad con los ADRs |
| 10 · Quality Requirements | Árbol de utilidad y 5 escenarios de calidad medibles |
| 12 · Glossary | Glosario de términos de dominio técnico y de negocio |

## Matriz comparativa de estilos

La comparación entre arquitectura por capas, hexagonal y monolito modular está en [`docs/matriz-comparativa-estilos.md`](docs/matriz-comparativa-estilos.md). La decisión adoptada combina un **Monolito Modular** como estructura general con **Hexagonal por módulo**.

## Diagramas C4

- **[Nivel 1 — Contexto](docs/c4/context.md):** actores del sistema, InvenTrack, y el servicio de notificaciones.
- **[Nivel 2 — Contenedores](docs/c4/containers.md):** desglose de contenedores ejecutables (Frontend Web/Móvil, API Backend FastAPI, Base de Datos y Servicio de Notificaciones).
- **[Árbol de utilidad](docs/utility-tree.md):** priorización de los escenarios de calidad por impacto de negocio y riesgo técnico.

Todos los diagramas están escritos en Mermaid y se renderizan directamente en GitHub.

## Decisiones de arquitectura (ADR)

Las decisiones arquitectónicas se documentan como archivos individuales en [`docs/adr/`](docs/adr/):

- **[ADR-0001](docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md):** Selección de Monolito Modular con Hexagonal por módulo para la estructura base.
- **[ADR-0002](docs/adr/0002-control-concurrencia-memoria-inventario.md):** Adopción de exclusión mutua asíncrona (`asyncio.Lock()`) por SKU para resolver el reto de consistencia ante peticiones simultáneas de inventario.

## Stack tecnológico

| Capa | Tecnología | Estado |
|---|---|---|
| Frontend | Por definir | Pendiente |
| Backend | FastAPI + Uvicorn | Implementado |
| Base de datos | Adaptador In-Memory (Transición a PostgreSQL/SQLite) | Implementado para MVP |
| Hosting / despliegue | Por definir | Pendiente |
| CI / calidad de código | GitHub Actions + Pytest | Operativo en verde |

## Estructura del repositorio

```text
.github/
└── workflows/
    └── test.yml                 # Pipeline de CI/CD para pruebas en GitHub Actions
docs/
├── arc42/
│   ├── arc42-template-EN.md     # Narrativa completa arc42
│   └── images/
│       └── arc42-logo.png
├── c4/
│   ├── context.md               # C4 Nivel 1 — Diagrama de contexto
│   └── containers.md            # C4 Nivel 2 — Diagrama de contenedores
├── adr/
│   ├── 0001-usar-monolito-modular-con-hexagonal-por-modulo.md
│   └── 0002-control-concurrencia-memoria-inventario.md
├── retos/
│   └── corte-1-medicion.md      # Diagnostico y medicion del Reto de Concurrencia
├── ficha_problema.md            # Planteamiento del problema
├── aspectos.md                  # Matriz de trazabilidad navegable de 8 columnas
├── matriz-comparativa-estilos.md# Comparativa de estilos arquitectónicos
├── utility-tree.md              # Árbol de utilidad
└── ia.md                        # Registro de uso de IA en el proyecto
app/                             # Aplicación FastAPI Monolito Modular
├── main.py                      # Composición y rutas principales
├── shared/                      # Dominio compartido y utilidades
├── productos/                   # Módulo de productos
├── inventario/                  # Módulo de inventario (Concurrencia por SKU)
├── proveedores/                 # Módulo de proveedores
├── usuarios/                    # Módulo de usuarios
└── alertas/                     # Módulo de alertas
tests/                           # Batería de pruebas automatizadas
├── test_health.py
├── productos/
└── inventario/
    └── test_concurrencia.py     # Pruebas de simulación concurrente (20 req)
requirements.txt                 # Dependencias del proyecto (FastAPI, pytest, httpx, etc.)
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

- Los cambios se integran en `main` manteniendo trazabilidad en cada commit.
- Cada hito o entrega de corte se identifica mediante su respectiva etiqueta en Git (ej. `corte-1`).
- Los enlaces internos en la documentación utilizan rutas relativas validadas.

## Progreso por semana

| Semana | Evidencia | Estado |
|---|---|---|
| S1 | Equipo, problema y repositorio | Completo |
| S2 | Escenarios de calidad y restricciones | Completo |
| S3 | Estrategia, matriz, ADR y esqueleto ejecutable | Completo |
| S4 | Vista de Contenedores (C4 N2), Secciones arc42 y Corte Vertical | Completo |
| Corte 1 | Reto de concurrencia e integración de inventario (ADR-0002 + Medición) | Completo |

## Uso de IA

Este proyecto documenta el uso de herramientas de IA de forma transparente en [`docs/ia.md`](docs/ia.md), detallando propuestas aceptadas y correcciones técnicas aplicadas por el equipo.

## Análisis estático

[![SonarCloud](https://sonarcloud.io/images/project_badges/sonarcloud-black.svg)](https://sonarcloud.io/project/overview?id=ISCOUTB_AS_202620_InvenTrack)

- Proyecto en SonarCloud: https://sonarcloud.io/project/overview?id=ISCOUTB_AS_202620_InvenTrack
- Project Key: `ISCOUTB_AS_202620_InvenTrack`
- Organization Key: `isco-utb`

La configuración del análisis estático incluye Python 3.11 y la separación entre `app` (fuente) y `tests` (pruebas) para una evaluación más precisa.

## Licencia y uso académico

Este repositorio es un proyecto académico desarrollado para el curso Arquitectura de Software (AS_202620) de la Universidad Tecnológica de Bolívar. Su contenido está sujeto a la política de uso responsable de IA y a las rúbricas del curso.

## Contacto

**Docente:** Jairo Serrano — jserrano@utb.edu.co

---

<div align="center">

Programa de Ingeniería de Sistemas y Computación · Universidad Tecnológica de Bolívar

</div>
