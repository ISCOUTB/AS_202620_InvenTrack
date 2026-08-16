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

Siguiendo el marco visto en clase — "cinco atributos, cinco preguntas"
(Rendimiento, Escalabilidad, Disponibilidad, Mantenibilidad, Seguridad) —
más el aspecto de calidad ya declarado en [`docs/aspectos.md`](../aspectos.md):

| Atributo | Pregunta guía (clase) | Respuesta para InvenTrack | Prioridad |
|---|---|---|---|
| **Consistencia de datos** *(aspecto declarado; fuera del marco de 5 preguntas)* | — | Movimientos concurrentes de distintos usuarios no deben producir stock negativo ni doble descuento del mismo movimiento. | Muy alta |
| Disponibilidad | ¿Qué fallos y recuperación? | El sistema debe seguir disponible en horario comercial; una caída se traduce en venta perdida o vuelta al papel. | Alta |
| Rendimiento | ¿Con qué carga y latencia? | Consultas y registros deben sentirse instantáneos en el mostrador, incluso en hora pico. | Media-alta |
| Seguridad | ¿Qué activo, amenaza y control? | Activo: historial de movimientos y datos personales de usuarios (restricción legal C1). Amenaza: suplantación o acceso sin el rol adecuado. Control: autenticación + roles. | Media-alta |
| Escalabilidad | ¿Qué crecimiento debe absorber? | Identificado, no priorizado: el piloto es una sola PYME; se revisa si el proyecto crece a varios negocios. | Baja por ahora |
| Mantenibilidad | ¿Qué cambio, esfuerzo y riesgo? | Identificado, no priorizado esta semana: se aborda junto con las decisiones de Building Block View. | Baja por ahora |

> **Usabilidad** también es relevante para el perfil de usuario descrito en
> la ficha (personas no técnicas, ver restricción C6), pero al aplicar el
> árbol de utilidad no alcanzó la misma prioridad que Seguridad, porque la
> protección de datos personales es además una restricción legal (C1) que
> no se puede posponer. Se documentará como aspecto propio si el equipo
> decide priorizarla en semanas futuras.
>
> **Pregunta guía de la clase — "¿qué atributo sacrificarían y a cambio de
> qué?":** si tuviéramos que elegir, sacrificaríamos algo de latencia
> (Rendimiento) a cambio de Consistencia, porque el aspecto declarado del
> proyecto prioriza la integridad del dato sobre la velocidad (ver el
> trade-off ESC-01 vs. ESC-04 en la sección 10.3).

## Stakeholders

Siguiendo las dos perspectivas trabajadas en clase para interpretar la
calidad desde responsabilidades concretas:

- **Usuario y negocio** → exige respuesta, costo y continuidad.
- **Operaciones y seguridad** → exige recuperación, control y trazabilidad.

| Rol | Perspectiva | Contacto | Expectativas |
|---|---|---|---|
| Dueño de la PYME (patrocinador / usuario principal) | Usuario y negocio | Equipo InvenTrack / negocio piloto | Ver el stock real en cualquier momento; tomar decisiones de compra con datos históricos; no depender de una sola persona para conocer el inventario. |
| Empleado / vendedor (usuario operativo) | Usuario y negocio | Equipo InvenTrack | Registrar entradas y salidas rápido, sin errores y sin capacitación extensa. |
| Administrador del sistema (rol dentro de la PYME) | Operaciones y seguridad | Equipo InvenTrack | Gestionar usuarios, permisos y catálogo de productos y proveedores; auditar quién hizo cada movimiento. |
| Proveedor (interesado indirecto, no usa el sistema) | Usuario y negocio (indirecto) | No aplica | Que la información de sus productos y órdenes quede registrada correctamente por el negocio. |
| Equipo de desarrollo / arquitectura (curso) | Operaciones y seguridad | Esteban Peluffo, Felix Taborda, Jose Vargas, Javier Carta — equipo AS_202620_InvenTrack | Poder evolucionar y mantener el sistema; decisiones arquitectónicas trazables (aspecto → requisito → C4 → ADR → código → pruebas → evidencia). |
| Docente / evaluador (interesado académico) | — (fuera del marco de negocio) | Jairo Serrano (jserrano@utb.edu.co) | Verificar que la arquitectura responde a los atributos de calidad declarados, con evidencia y trazabilidad real. |

# Architecture Constraints

Restricción entendida como condición impuesta desde fuera, que acota el
espacio de solución antes de diseñar: no se negocia con el diseño, se acata
o se escala. Se distingue de un requisito (lo que el sistema debe hacer).

| # | Tipo | Restricción | Quién la impone / justificación |
|---|---|---|---|
| C1 | Legal | Los datos personales de usuarios y clientes deben protegerse conforme a la Ley 1581 de 2012 (protección de datos personales, Colombia): credenciales cifradas, acceso restringido por rol. | Legislación colombiana. No se puede decidir no cumplirla. |
| C2 | Organizativa | El repositorio debe alojarse en la organización GitHub `ISCOUTB` con la estructura fija del curso (`/docs/arc42`, [`/docs/adr`](../adr/), [`/docs/c4`](../c4/), [`docs/aspectos.md`](../aspectos.md), [`docs/ia.md`](../ia.md)). | Impuesta por el curso AS_202620. |
| C3 | Organizativa | El código debe poder evaluarse de forma continua con SonarCloud. | Impuesta por el curso (recurso "Sonarcloud" en Inicio y orientación). |
| C4 | Organizativa | Equipo de 3–4 personas con dedicación parcial (curso de un semestre) y entregas semanales fijas los domingos. | Calendario académico; limita cuánto alcance se construye por iteración y obliga a priorizar el MVP declarado en la ficha del problema. |
| C5 | Técnica | Sin presupuesto para servicios de pago; debe usarse stack y hosting con capa gratuita/open source. | Restricción real del contexto: son PYMEs sin músculo financiero para licencias, y el equipo no cuenta con presupuesto del curso. |
| C6 | Técnica | La interfaz debe ser utilizable por personas con alfabetización digital variable, que hoy trabajan con Excel o papel. | Perfil real de los usuarios objetivo descrito en la ficha del problema; condiciona la complejidad admisible de los flujos. |
| C7 | Técnica (pendiente de confirmar) | Conectividad e infraestructura de despliegue disponibles en las PYMEs piloto. | Se resolverá con la encuesta "Disponibilidad técnica y de despliegue" (Inicio y orientación); hasta entonces se asume acceso vía navegador web estándar. |

## Implicaciones arquitectónicas de las restricciones

Las restricciones anteriores tienen consecuencias directas sobre las decisiones arquitectónicas de InvenTrack.

## C1 — Protección de datos personales

La arquitectura deberá contemplar mecanismos para proteger las credenciales y restringir el acceso a información según los permisos correspondientes. Esto implica que la autenticación y autorización no pueden tratarse únicamente como características de la interfaz, sino que deben estar respaldadas por el servidor.

## C2 — Estructura del repositorio

La documentación y los artefactos arquitectónicos deberán organizarse de acuerdo con la estructura establecida por el curso. Las decisiones arquitectónicas, diagramas C4, documentación arc42 y aspectos de calidad deberán mantenerse dentro de los directorios correspondientes.

## C3 — SonarCloud

La estructura y las tecnologías utilizadas deberán permitir realizar análisis automatizados de calidad del código. Por tanto, se debe evitar una arquitectura que dificulte la integración del proyecto con herramientas de análisis estático.

## C4 — Tiempo y tamaño del equipo

La arquitectura debe mantenerse suficientemente sencilla para que pueda ser implementada y mantenida por un equipo pequeño durante un semestre. Esto justifica priorizar el MVP frente a funcionalidades avanzadas que no sean necesarias para resolver el problema principal.

El MVP contempla:

Gestión de productos.
Gestión de proveedores.
Registro de entradas y salidas.
Consulta del inventario actual.
Gestión de usuarios.
Historial de movimientos.
Alertas de stock bajo.

La predicción de demanda mediante modelos históricos queda fuera del alcance actual y se considera una posible extensión futura.

## C5 — Presupuesto

La arquitectura debe favorecer tecnologías y servicios que puedan ejecutarse sin costos de licencia o infraestructura durante el desarrollo del MVP. Esto limita la selección de servicios propietarios que requieran planes de pago.

## C6 — Perfil de los usuarios

La interfaz debe evitar flujos innecesariamente complejos y presentar las operaciones principales de forma clara. Esta decisión responde a que los usuarios objetivo son dueños y empleados de pequeñas y medianas empresas que actualmente pueden trabajar mediante procesos manuales o herramientas desarticuladas.
 
## C7 — Infraestructura y conectividad

Mientras la disponibilidad técnica de las PYMEs piloto no haya sido confirmada, la arquitectura deberá asumir como escenario base el acceso mediante un navegador web estándar. La decisión podrá revisarse posteriormente si la encuesta identifica limitaciones importantes de conectividad o infraestructura.

# Context and Scope

## Business Context

**Diagrama C4 Nivel 1 (Contexto del sistema):** ver [`docs/c4/context.md`](../c4/context.md).

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

*(Los ADR viven como archivos individuales en [`docs/adr/`](../adr/); aquí
se puede enlazar la lista cuando existan.)*

# Quality Requirements

## Quality Requirements Overview

**De la preocupación al atributo (método visto en clase, aplicado a
InvenTrack):**

> Preocupación (Dueño/Empleado): *"las consultas de inventario se demoran
> en hora pico."*
> Atributo: eficiencia de desempeño (Rendimiento).
> Escenario: ver **ESC-04** más abajo, con sus seis partes.
> Evidencia: prueba de carga, midiendo el percentil p95. Población:
> consultas de listado de inventario. Ventana: hora pico (12 m.–2 p. m.).
> Carga: 20 usuarios concurrentes. Método: prueba de carga automatizada.

Este mismo método (preocupación → atributo → escenario de seis partes →
evidencia) se aplicó a los otros cuatro escenarios de esta sección.

**Árbol de utilidad** (Utilidad → atributo → refinamiento → escenario,
priorizado como (impacto en el negocio, riesgo técnico); H=alto, M=medio,
L=bajo). Fuente Mermaid en [`docs/c4/utility-tree.md`](../c4/utility-tree.md).

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
├─ Rendimiento
│   └─ Tiempo de respuesta en consulta de inventario
│       └─ ESC-04 Consulta de stock en hora pico (M, L)
└─ Seguridad
    └─ Control de acceso por rol
        └─ ESC-05 Intento de acceso sin autenticación o sin rol suficiente (M, M)
```

Los escenarios con mayor impacto de negocio y/o riesgo técnico (ESC-01,
ESC-03) orientan las primeras decisiones arquitectónicas: control de
concurrencia y estrategia de disponibilidad, respectivamente.

## Quality Scenarios

Cada escenario sigue el formato de seis partes visto en clase: **Fuente +
Estímulo + Artefacto + Entorno → Respuesta + Medida verificable.**

### ESC-01 — Consistencia de datos (aspecto declarado)

*Perspectiva: Operaciones y seguridad · Prioridad (H, H)*

- **Fuente:** dos empleados usando el sistema al mismo tiempo.
- **Estímulo:** registran una salida de inventario del mismo producto simultáneamente.
- **Artefacto:** módulo de registro de movimientos y stock.
- **Entorno:** operación normal, horario comercial.
- **Respuesta:** el sistema serializa las transacciones concurrentes y aplica ambos descuentos de forma consistente, o rechaza uno si el stock resultante sería negativo.
- **Medida (verificable):** 0 casos de stock negativo y 0 casos de doble descuento del mismo movimiento en el 100 % de una prueba de concurrencia con 50 transacciones simultáneas sobre el mismo producto.

### ESC-02 — Consistencia de datos (integridad referencial)

*Perspectiva: Operaciones y seguridad · Prioridad (M, M)*

- **Fuente:** usuario administrador.
- **Estímulo:** intenta eliminar un producto con movimientos históricos asociados.
- **Artefacto:** módulo de gestión de productos.
- **Entorno:** operación normal.
- **Respuesta:** el sistema impide el borrado físico y solo permite desactivar (borrado lógico) el producto.
- **Medida (verificable):** 100 % de los productos con movimientos asociados no pueden eliminarse físicamente; verificado con prueba automatizada.

### ESC-03 — Disponibilidad

*Perspectiva: Usuario y negocio · Prioridad (H, M) · Pregunta guía: ¿qué fallos y recuperación?*

- **Fuente:** falla de infraestructura (caída del servidor).
- **Estímulo:** el servicio deja de responder mientras un empleado registra una venta.
- **Artefacto:** sistema completo (backend).
- **Entorno:** horario comercial pico.
- **Respuesta:** el sistema se recupera y el movimiento no confirmado no queda aplicado parcialmente.
- **Medida (verificable):** disponibilidad ≥ 99 % mensual en horario comercial (8 a. m.–8 p. m.) y recuperación en ≤ 5 minutos tras una falla, medido con monitoreo de uptime.

### ESC-04 — Rendimiento

*Perspectiva: Usuario y negocio · Prioridad (M, L) · Pregunta guía: ¿con qué carga y latencia?*

- **Fuente:** empleado o dueño.
- **Estímulo:** consulta el inventario actual con filtros.
- **Artefacto:** módulo de consulta de inventario.
- **Entorno:** hora pico, hasta 20 usuarios concurrentes.
- **Respuesta:** el sistema retorna el listado solicitado.
- **Medida (verificable):** ≤ 400 ms p95 con 20 usuarios concurrentes, medido con prueba de carga. (p95 = al menos el 95 % de las observaciones no supera ese tiempo; se define población, ventana, carga y método de medición para que el número sea reproducible.)

### ESC-05 — Seguridad

*Perspectiva: Operaciones y seguridad · Prioridad (M, M) · Pregunta guía: ¿qué activo, amenaza y control?*

- **Fuente:** usuario sin sesión válida, o autenticado pero sin el rol requerido (ej. empleado intentando una acción de administrador).
- **Estímulo:** intenta iniciar sesión con credenciales inválidas, o intenta ejecutar una acción restringida (gestionar usuarios, eliminar producto) sin permiso suficiente.
- **Artefacto:** módulo de autenticación y control de acceso por roles.
- **Entorno:** operación normal, cualquier momento, incluidos intentos repetidos.
- **Respuesta:** el sistema rechaza la operación, no expone datos ni funciones fuera del rol del usuario, y registra el intento en el log de auditoría.
- **Medida (verificable):** 100 % de los intentos de acceso sin sesión válida o sin rol suficiente son rechazados y quedan registrados, verificado con pruebas de control de acceso sobre los roles definidos (Dueño, Administrador, Empleado).

> Cada escenario se enlaza desde la fila correspondiente de
> [`docs/aspectos.md`](../aspectos.md). ESC-01 y ESC-02 pertenecen al aspecto "Consistencia
> de datos" declarado en la Evidencia S1; el resto (ESC-03 a ESC-05)
> corresponde a atributos de calidad priorizados pero aún sin un aspecto
> propio declarado.

## Trade-offs y tensiones identificadas

Retomando la idea de clase de que "una táctica puede mejorar un atributo y
afectar otro" y que "la decisión se justifica con escenarios y evidencia,
no con reglas absolutas":

- **Consistencia (ESC-01) vs. Rendimiento (ESC-04):** garantizar
  consistencia estricta en movimientos concurrentes (por ejemplo, bloqueos
  pesimistas o transacciones serializables) puede aumentar la latencia de
  las escrituras bajo carga. Es el trade-off que responde a la pregunta
  guía "¿qué atributo sacrificarían y a cambio de qué?": este equipo
  prioriza Consistencia sobre Rendimiento, porque el aspecto declarado del
  proyecto es la integridad del dato, no la velocidad.
- **Consistencia (ESC-01/ESC-02) vs. Disponibilidad (ESC-03):** el ejemplo
  visto en clase — "Réplicas: disponibilidad ↑; costo y consistencia se
  tensionan" — aplica directamente aquí. Si más adelante el equipo decide
  replicar la base de datos para mejorar disponibilidad, esa decisión
  deberá evaluarse primero contra ESC-01 y ESC-02, porque la consistencia
  es el aspecto declarado y no se negocia sin justificación explícita.
- **Seguridad (ESC-05) vs. Usabilidad:** exigir autenticación y control de
  roles añade fricción para usuarios no técnicos (restricción C6). Se
  buscará que el mecanismo de control de acceso sea simple de usar sin
  debilitar la medida de ESC-05.

Estas tensiones no se resuelven todavía: se documentarán como ADR en
[`docs/adr/`](../adr/) cuando el equipo decida la táctica concreta para
cada atributo.

# Risks and Technical Debts

*(Pendiente.)*

# Glossary

| Término | Definición |
|---|---|
| Aspecto | Porción del sistema con valor propio, recorrible de punta a punta (necesidad → evidencia). |
| Escenario de calidad | Fuente + estímulo + artefacto + entorno + respuesta + medida verificable. |
| ADR | Architecture Decision Record: registro de una decisión arquitectónica, su contexto y sus consecuencias. |
