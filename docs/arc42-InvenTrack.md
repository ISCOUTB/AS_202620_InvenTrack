---
date: July 2025
title: "![arc42](images/arc42-logo.png) Template"
---

# 

**About arc42**

arc42, the template for documentation of software and system
architecture.

Template Version 9.0-EN. (based upon AsciiDoc version), July 2025

Created, maintained and © by Dr. Peter Hruschka, Dr. Gernot Starke and
contributors. See <https://arc42.org>.

# Introduction and Goals {#section-introduction-and-goals}

## Requirements Overview {#_requirements_overview}

Las pequeñas y medianas empresas en Cartagena (tiendas, distribuidoras,
minimercados, ferreterías) gestionan su inventario principalmente en Excel o
en papel. Esto produce descuadres de stock, quiebres no detectados a tiempo,
compras mal planificadas por falta de datos históricos, ausencia de
trazabilidad sobre los movimientos y dependencia de una sola persona como
punto único de fallo operativo.

**InvenTrack** es un sistema de gestión de inventarios que centraliza
productos, proveedores, entradas y salidas de mercancía, con control de
usuarios y trazabilidad completa de cada movimiento, además de alertas
automáticas cuando el stock de un producto baja de un umbral crítico.

Alcance del MVP de esta entrega:

- Gestión de productos
- Gestión de proveedores
- Registro de entradas y salidas
- Consulta de inventario actual
- Gestión de usuarios
- Historial de movimientos (trazabilidad)
- Alertas de stock bajo

Fuera de alcance por ahora: predicción de demanda mediante modelos
históricos; se contempla como extensión futura sin comprometer la base
arquitectónica.

## Quality Goals {#_quality_goals}

Priorizados según su impacto en el negocio y el riesgo técnico (ver árbol
de utilidad en la sección 10):

| # | Atributo de calidad | Motivación |
|---|---|---|
| 1 | **Consistencia de datos** (aspecto declarado en `docs/aspectos.md`) | Movimientos simultáneos de distintos usuarios no deben producir stock negativo ni doble descuento del mismo movimiento. |
| 2 | **Disponibilidad** | El sistema reemplaza el registro manual; si no responde en horario comercial, el negocio pierde la venta o vuelve al papel. |
| 3 | **Usabilidad** | Los usuarios objetivo no tienen formación técnica y hoy trabajan con Excel o papel; la curva de aprendizaje debe ser mínima. |
| 4 | **Eficiencia de desempeño** | Las consultas de inventario y el registro de movimientos deben sentirse instantáneos en el mostrador, incluso en hora pico. |
| 5 | **Seguridad** | El control de usuarios y la trazabilidad exigen que cada movimiento quede asociado a quién lo hizo, sin que se pueda suplantar a otro usuario. |

## Stakeholders {#_stakeholders}

+-------------------------+---------------------------+-------------------------------------------------------------+
| Role/Name                | Contact                   | Expectations                                                 |
+===========================+===========================+===============================================================+
| *Dueño de la PYME          | *Equipo InvenTrack /       | *Ver el stock real en cualquier momento; tomar decisiones     |
| (patrocinador / usuario    | representante del negocio | de compra con datos históricos; no depender de una sola       |
| principal)*                | piloto*                   | persona para conocer el inventario.*                          |
+-------------------------+---------------------------+-------------------------------------------------------------+
| *Empleado / vendedor       | *Equipo InvenTrack*        | *Registrar entradas y salidas de forma rápida, sin errores    |
| (usuario operativo)*       |                            | y sin necesidad de capacitación extensa.*                     |
+-------------------------+---------------------------+-------------------------------------------------------------+
| *Administrador del         | *Equipo InvenTrack*        | *Gestionar usuarios, permisos y catálogo de productos y       |
| sistema (rol dentro de     |                            | proveedores; auditar quién hizo cada movimiento.*              |
| la PYME)*                  |                            |                                                                |
+-------------------------+---------------------------+-------------------------------------------------------------+
| *Proveedor (interesado     | *No usa el sistema          | *Que la información de sus productos y órdenes quede          |
| indirecto, no usa el       | directamente*              | registrada correctamente por parte del negocio.*               |
| sistema)*                  |                            |                                                                |
+-------------------------+---------------------------+-------------------------------------------------------------+
| *Equipo de desarrollo /     | *Equipo AS_202620_         | *Poder evolucionar y mantener el sistema; decisiones           |
| arquitectura (curso)*      | InvenTrack*                | arquitectónicas trazables (aspecto → requisito → C4 →         |
|                            |                            | ADR → código → pruebas → evidencia).*                          |
+-------------------------+---------------------------+-------------------------------------------------------------+
| *Docente / evaluador        | *Jairo Serrano             | *Verificar que la arquitectura responde a los atributos de    |
| (interesado académico)*    | (jserrano@utb.edu.co)*     | calidad declarados, con evidencia y trazabilidad real.*        |
+-------------------------+---------------------------+-------------------------------------------------------------+

# Architecture Constraints {#section-architecture-constraints}

Restricción entendida como condición impuesta desde fuera, que acota el
espacio de solución antes de diseñar: no se negocia con el diseño, se acata
o se escala. Se distingue de un requisito (lo que el sistema debe hacer).

| # | Tipo | Restricción | Quién la impone / justificación |
|---|---|---|---|
| C1 | Legal | Los datos personales de usuarios y clientes deben protegerse conforme a la Ley 1581 de 2012 (protección de datos personales, Colombia): credenciales cifradas, acceso restringido por rol. | Legislación colombiana. No se puede decidir no cumplirla. |
| C2 | Organizativa | El repositorio debe alojarse en la organización GitHub `ISCOUTB` con la estructura fija del curso (`/docs/arc42`, `/docs/adr`, `/docs/c4`, `docs/aspectos.md`, `docs/ia.md`). | Impuesta por el curso AS_202620. |
| C3 | Organizativa | El código debe poder evaluarse de forma continua con SonarCloud. | Impuesta por el curso (recurso "Sonarcloud" en Inicio y orientación). |
| C4 | Organizativa | Equipo de 3–4 personas con dedicación parcial (curso de un semestre) y entregas semanales fijas los domingos. | Calendario académico; limita cuánto alcance se construye por iteración y obliga a priorizar el MVP declarado en la ficha del problema. |
| C5 | Técnica | Sin presupuesto para servicios de pago; debe usarse stack y hosting con capa gratuita/open source. | Restricción real del contexto: son PYMEs sin músculo financiero para licencias, y el equipo no cuenta con presupuesto del curso. |
| C6 | Técnica | La interfaz debe ser utilizable por personas con alfabetización digital variable, que hoy trabajan con Excel o papel. | Perfil real de los usuarios objetivo descrito en la ficha del problema; condiciona la complejidad admisible de los flujos. |
| C7 | Técnica (pendiente de confirmar) | Conectividad e infraestructura de despliegue disponibles en las PYMEs piloto. | Se resolverá con la encuesta "Disponibilidad técnica y de despliegue" (Inicio y orientación); hasta entonces se asume acceso vía navegador web estándar. |

# Context and Scope {#section-context-and-scope}

## Business Context {#_business_context}

**Diagrama C4 Nivel 1 (Contexto del sistema):** ver `docs/c4/context.md`
(fuente Mermaid) y la imagen exportada en este mismo documento.

InvenTrack tiene dos actores humanos que interactúan directamente con el
sistema, y un canal externo de notificación:

| Actor / sistema externo | Tipo | Interacción con InvenTrack |
|---|---|---|
| Dueño de la PYME | Persona | Consulta inventario, reportes e historial de movimientos; gestiona usuarios y proveedores. |
| Empleado / vendedor | Persona | Registra entradas y salidas de mercancía; consulta stock actual. |
| Servicio de notificaciones (correo electrónico) | Sistema externo | Recibe la solicitud de alerta cuando un producto baja del umbral crítico y la entrega al destinatario. |
| Proveedor | No interactúa con el sistema | Sus datos (catálogo, órdenes) son ingresados manualmente por el dueño o el empleado; no hay integración directa en el MVP. |

## Technical Context {#_technical_context}

Pendiente de decisión formal (se documentará como ADR cuando se defina el
stack, ver recurso "Stack de Desarrollo" en Inicio y orientación). Para esta
entrega se asumen los siguientes canales técnicos, consistentes con la
restricción C5 (sin presupuesto para servicios de pago) y C7 (conectividad
por confirmar):

| Canal | Protocolo/formato | Entre |
|---|---|---|
| Interfaz de usuario | HTTPS | Navegador del Dueño/Empleado ↔ InvenTrack |
| Envío de alertas | SMTP / API de correo | InvenTrack → Servicio de notificaciones (correo electrónico) |

# Solution Strategy {#section-solution-strategy}

# Building Block View {#section-building-block-view}

## Whitebox Overall System {#_whitebox_overall_system}

***\<Overview Diagram\>***

Motivation

:   *\<text explanation\>*

Contained Building Blocks

:   *\<Description of contained building block (black boxes)\>*

Important Interfaces

:   *\<Description of important interfaces\>*

### \<Name black box 1\> {#_name_black_box_1}

*\<Purpose/Responsibility\>*

*\<Interface(s)\>*

*\<(Optional) Quality/Performance Characteristics\>*

*\<(Optional) Directory/File Location\>*

*\<(Optional) Fulfilled Requirements\>*

*\<(optional) Open Issues/Problems/Risks\>*

### \<Name black box 2\> {#_name_black_box_2}

*\<black box template\>*

### \<Name black box n\> {#_name_black_box_n}

*\<black box template\>*

### \<Name interface 1\> {#_name_interface_1}

...​

### \<Name interface m\> {#_name_interface_m}

## Level 2 {#_level_2}

### White Box *\<building block 1\>* {#_white_box_building_block_1}

*\<white box template\>*

### White Box *\<building block 2\>* {#_white_box_building_block_2}

*\<white box template\>*

...​

### White Box *\<building block m\>* {#_white_box_building_block_m}

*\<white box template\>*

## Level 3 {#_level_3}

### White Box \<\_building block x.1\_\> {#_white_box_building_block_x_1}

*\<white box template\>*

### White Box \<\_building block x.2\_\> {#_white_box_building_block_x_2}

*\<white box template\>*

### White Box \<\_building block y.1\_\> {#_white_box_building_block_y_1}

*\<white box template\>*

# Runtime View {#section-runtime-view}

## \<Runtime Scenario 1\> {#_runtime_scenario_1}

-   *\<insert runtime diagram or textual description of the scenario\>*

-   *\<insert description of the notable aspects of the interactions
    between the building block instances depicted in this diagram.\>*

## \<Runtime Scenario 2\> {#_runtime_scenario_2}

## ...​

## \<Runtime Scenario n\> {#_runtime_scenario_n}

# Deployment View {#section-deployment-view}

## Infrastructure Level 1 {#_infrastructure_level_1}

***\<Overview Diagram\>***

Motivation

:   *\<explanation in text form\>*

Quality and/or Performance Features

:   *\<explanation in text form\>*

Mapping of Building Blocks to Infrastructure

:   *\<description of the mapping\>*

## Infrastructure Level 2 {#_infrastructure_level_2}

### *\<Infrastructure Element 1\>* {#_infrastructure_element_1}

*\<diagram + explanation\>*

### *\<Infrastructure Element 2\>* {#_infrastructure_element_2}

*\<diagram + explanation\>*

...​

### *\<Infrastructure Element n\>* {#_infrastructure_element_n}

*\<diagram + explanation\>*

# Cross-cutting Concepts {#section-concepts}

## *\<Concept 1\>* {#_concept_1}

*\<explanation\>*

## *\<Concept 2\>* {#_concept_2}

*\<explanation\>*

...​

## *\<Concept n\>* {#_concept_n}

*\<explanation\>*

# Architecture Decisions {#section-design-decisions}

# Quality Requirements {#section-quality-scenarios}

## Quality Requirements Overview {#_quality_requirements_overview}

**Árbol de utilidad** (Utilidad → atributo → refinamiento → escenario,
priorizado como (impacto en el negocio, riesgo técnico); H=alto, M=medio,
L=bajo). Fuente Mermaid en `docs/c4/utility-tree.md`.

```
Utilidad de InvenTrack
├─ Consistencia de datos (aspecto declarado)
│   ├─ Concurrencia en movimientos de inventario
│   │   └─ ESC-01 Registro simultáneo de salida del mismo producto (H, H)
│   └─ Integridad referencial del catálogo
│       └─ ESC-02 Eliminar producto con movimientos asociados (M, M)
├─ Disponibilidad
│   └─ Continuidad operativa en horario comercial
│       └─ ESC-03 Caída del servidor durante el registro de una venta (H, M)
├─ Eficiencia de desempeño
│   └─ Tiempo de respuesta en consulta de inventario
│       └─ ESC-04 Consulta de stock en hora pico (M, L)
└─ Usabilidad
    └─ Facilidad de aprendizaje para usuarios no técnicos
        └─ ESC-05 Empleado nuevo registra una entrada sin capacitación (H, L)
```

Los escenarios ESC-01 y ESC-03 (mayor impacto de negocio y/o riesgo
técnico) orientan las primeras decisiones arquitectónicas (control de
concurrencia y estrategia de disponibilidad).

## Quality Scenarios {#_quality_scenarios}

+--------+------------------------+---------------------------------------+------------------------------------+------------------------------+------------------------------------------------------------+----------------------------------------------------------------------------+
| ID     | Atributo               | Fuente                                 | Estímulo                            | Artefacto / Entorno          | Respuesta                                                    | Medida de respuesta                                                          |
+========+========================+=========================================+======================================+================================+================================================================+================================================================================+
| ESC-01 | Consistencia de datos   | Dos empleados usando el sistema          | Registran una salida de inventario   | Módulo de registro de         | El sistema serializa las transacciones concurrentes y aplica  | 0 casos de stock negativo y 0 casos de doble descuento del mismo             |
|        | (declarado)             | al mismo tiempo                          | del mismo producto simultáneamente   | movimientos / stock;          | ambos descuentos de forma consistente, o rechaza uno si el    | movimiento en el 100 % de una prueba de concurrencia con 50 transacciones    |
|        |                        |                                          |                                      | operación normal, horario     | stock resultante sería negativo                                | simultáneas sobre el mismo producto                                          |
|        |                        |                                          |                                      | comercial                     |                                                                |                                                                                |
+--------+------------------------+---------------------------------------+------------------------------------+------------------------------+------------------------------------------------------------+----------------------------------------------------------------------------+
| ESC-02 | Consistencia de datos   | Usuario administrador                    | Intenta eliminar un producto con     | Módulo de gestión de          | El sistema impide el borrado físico y solo permite            | 100 % de los productos con movimientos asociados no pueden eliminarse        |
|        | (integridad             |                                          | movimientos históricos asociados     | productos; operación normal    | desactivar (borrado lógico) el producto                        | físicamente; verificado con prueba automatizada                              |
|        | referencial)            |                                          |                                      |                                |                                                                |                                                                                |
+--------+------------------------+---------------------------------------+------------------------------------+------------------------------+------------------------------------------------------------+----------------------------------------------------------------------------+
| ESC-03 | Disponibilidad          | Falla de infraestructura                 | El servicio deja de responder        | Sistema completo (backend);   | El sistema se recupera y el movimiento no confirmado no        | Disponibilidad ≥ 99 % mensual en horario comercial (8 a. m.–8 p. m.) y      |
|        |                        | (caída del servidor)                     | mientras un empleado registra una    | horario comercial pico        | queda aplicado parcialmente                                    | recuperación en ≤ 5 minutos tras una falla, medido con monitoreo de uptime  |
|        |                        |                                          | venta                                |                                |                                                                |                                                                                |
+--------+------------------------+---------------------------------------+------------------------------------+------------------------------+------------------------------------------------------------+----------------------------------------------------------------------------+
| ESC-04 | Eficiencia de desempeño | Empleado o dueño                         | Consulta el inventario actual con    | Módulo de consulta de         | El sistema retorna el listado solicitado                       | ≤ 400 ms p95 con 20 usuarios concurrentes, medido con prueba de carga        |
|        |                        |                                          | filtros                              | inventario; hora pico, hasta  |                                                                |                                                                                |
|        |                        |                                          |                                      | 20 usuarios concurrentes      |                                                                |                                                                                |
+--------+------------------------+---------------------------------------+------------------------------------+------------------------------+------------------------------------------------------------+----------------------------------------------------------------------------+
| ESC-05 | Usabilidad              | Empleado nuevo sin capacitación previa    | Debe registrar una entrada de        | Interfaz de registro de       | Completa el registro correctamente guiándose solo por la      | ≥ 90 % de usuarios nuevos completan el registro sin asistencia en           |
|        |                        | (viene de Excel o papel)                  | mercancía por primera vez            | movimientos; primer uso, sin  | interfaz                                                       | ≤ 3 minutos, medido en prueba de usabilidad con 5 usuarios representativos   |
|        |                        |                                          |                                      | manual impreso                |                                                                |                                                                                |
+--------+------------------------+---------------------------------------+------------------------------------+------------------------------+------------------------------------------------------------+----------------------------------------------------------------------------+

> Cada escenario se enlaza desde la fila correspondiente de
> `docs/aspectos.md`. ESC-01 y ESC-02 pertenecen al aspecto "Consistencia
> de datos" declarado en la Evidencia S1.

# Risks and Technical Debts {#section-technical-risks}

# Glossary {#section-glossary}

+----------------------+-----------------------------------------------+
| Term                 | Definition                                    |
+======================+===============================================+
| *\<Term-1\>*         | *\<definition-1\>*                            |
+----------------------+-----------------------------------------------+
| *\<Term-2\>*         | *\<definition-2\>*                            |
+----------------------+-----------------------------------------------+
