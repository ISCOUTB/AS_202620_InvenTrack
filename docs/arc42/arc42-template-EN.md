# ![arc42](images/arc42-logo.png) InvenTrack — Documentación de Arquitectura (arc42)

Plantilla arc42 v9.0-EN (versión académica). Fuente: <https://arc42.org>.

# Introduction and Goals

## Requirements Overview

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

## Quality Goals

Priorizados según su impacto en el negocio y el riesgo técnico (ver árbol
de utilidad en la sección 10):

| # | Atributo de calidad | Motivación |
|---|---|---|
| 1 | **Consistencia de datos** (aspecto declarado en `docs/aspectos.md`) | Movimientos simultáneos de distintos usuarios no deben producir stock negativo ni doble descuento del mismo movimiento. |
| 2 | **Disponibilidad** | El sistema reemplaza el registro manual; si no responde en horario comercial, el negocio pierde la venta o vuelve al papel. |
| 3 | **Usabilidad** | Los usuarios objetivo no tienen formación técnica y hoy trabajan con Excel o papel; la curva de aprendizaje debe ser mínima. |
| 4 | **Eficiencia de desempeño** | Las consultas de inventario y el registro de movimientos deben sentirse instantáneos en el mostrador, incluso en hora pico. |
| 5 | **Seguridad** | El control de usuarios y la trazabilidad exigen que cada movimiento quede asociado a quién lo hizo, sin que se pueda suplantar a otro usuario. |

## Stakeholders

| Rol | Contacto | Expectativas |
|---|---|---|
| Dueño de la PYME (patrocinador / usuario principal) | Equipo InvenTrack / negocio piloto | Ver el stock real en cualquier momento; tomar decisiones de compra con datos históricos; no depender de una sola persona para conocer el inventario. |
| Empleado / vendedor (usuario operativo) | Equipo InvenTrack | Registrar entradas y salidas rápido, sin errores y sin capacitación extensa. |
| Administrador del sistema (rol dentro de la PYME) | Equipo InvenTrack | Gestionar usuarios, permisos y catálogo de productos y proveedores; auditar quién hizo cada movimiento. |
| Proveedor (interesado indirecto, no usa el sistema) | No aplica | Que la información de sus productos y órdenes quede registrada correctamente por el negocio. |
| Equipo de desarrollo / arquitectura (curso) | Equipo AS_202620_InvenTrack — *(completar con nombres y correos institucionales del equipo)* | Poder evolucionar y mantener el sistema; decisiones arquitectónicas trazables (aspecto → requisito → C4 → ADR → código → pruebas → evidencia). |
| Docente / evaluador (interesado académico) | Jairo Serrano (jserrano@utb.edu.co) | Verificar que la arquitectura responde a los atributos de calidad declarados, con evidencia y trazabilidad real. |

# Architecture Constraints

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

# Context and Scope

## Business Context

**Diagrama C4 Nivel 1 (Contexto del sistema):** ver `docs/c4/context.md`.

InvenTrack tiene dos actores humanos que interactúan directamente con el
sistema, y un canal externo de notificación:

| Actor / sistema externo | Tipo | Interacción con InvenTrack |
|---|---|---|
| Dueño de la PYME | Persona | Consulta inventario, reportes e historial de movimientos; gestiona usuarios y proveedores. |
| Empleado / vendedor | Persona | Registra entradas y salidas de mercancía; consulta stock actual. |
| Servicio de notificaciones (correo electrónico) | Sistema externo | Recibe la solicitud de alerta cuando un producto baja del umbral crítico y la entrega al destinatario. |
| Proveedor | No interactúa con el sistema | Sus datos (catálogo, órdenes) son ingresados manualmente por el dueño o el empleado; no hay integración directa en el MVP. |

## Technical Context

Pendiente de decisión formal (se documentará como ADR cuando se defina el
stack, ver recurso "Stack de Desarrollo" en Inicio y orientación). Para esta
entrega se asumen los siguientes canales técnicos, consistentes con la
restricción C5 (sin presupuesto para servicios de pago) y C7 (conectividad
por confirmar):

| Canal | Protocolo/formato | Entre |
|---|---|---|
| Interfaz de usuario | HTTPS | Navegador del Dueño/Empleado ↔ InvenTrack |
| Envío de alertas | SMTP / API de correo | InvenTrack → Servicio de notificaciones (correo electrónico) |

# Solution Strategy

*(Se completa en semanas posteriores, cuando el equipo decida el stack y las tácticas para cada atributo de calidad.)*

# Building Block View

## Whitebox Overall System

*(Pendiente — se completa cuando exista una primera versión del sistema.)*

## Level 2

## Level 3

# Runtime View

*(Pendiente.)*

# Deployment View

## Infrastructure Level 1

*(Pendiente — se completa en la semana 8, "Guía de despliegue y costos".)*

## Infrastructure Level 2

# Cross-cutting Concepts

*(Pendiente.)*

# Architecture Decisions

*(Los ADR viven como archivos individuales en `docs/adr/`; aquí se puede
enlazar la lista cuando existan.)*

# Quality Requirements

## Quality Requirements Overview

**Árbol de utilidad** (Utilidad → atributo → refinamiento → escenario,
priorizado como (impacto en el negocio, riesgo técnico); H=alto, M=medio,
L=bajo). Fuente Mermaid en `docs/c4/utility-tree.md`.
