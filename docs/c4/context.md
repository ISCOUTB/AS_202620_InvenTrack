# C4 Nivel 1 — Diagrama de Contexto — InvenTrack

## Qué muestra este nivel y por qué

El modelo C4 documenta la arquitectura en niveles de zoom: Contexto
(Nivel 1) → Contenedores (Nivel 2) → Componentes (Nivel 3) → Código
(Nivel 4). Cada nivel abstrae detalle del anterior en vez de repetirlo.

Este diagrama es el **Nivel 1: Contexto**. Responde una sola pregunta:
*¿quién usa el sistema y con qué otros sistemas se conecta?* Por diseño,
**no** muestra nada de lo que hay adentro de InvenTrack (eso es el Nivel 2,
Contenedores, que se documentará más adelante cuando el equipo decida el
stack). Tratar a InvenTrack como una caja cerrada en este nivel es
intencional: sirve para acordar el alcance del sistema con los
interesados antes de discutir cómo se construye por dentro.

```mermaid
<svg width="680" height="590" viewBox="0 0 680 590" xmlns="http://www.w3.org/2000/svg" font-family="Segoe UI, Arial, sans-serif">
<title>Diagrama de contexto C4 Nivel 1 de InvenTrack</title>
<desc>Tres personas (Dueño-Administrador, Vendedor-Operador de Ventas, Empleado de bodega-Operador de Inventario) usan InvenTrack por HTTPS. InvenTrack envía alertas por SMTP a Notificaciones, que entrega a una Bandeja final.</desc>

<rect width="680" height="590" fill="#ffffff"/>

<defs>
<marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
  <path d="M2 1L8 5L2 9" fill="none" stroke="#555555" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</marker>
</defs>

<!-- Dueño de la PYME -->
<rect x="30" y="30" width="200" height="130" rx="10" fill="#1168bd" stroke="#0b4884" stroke-width="1"/>
<circle cx="130" cy="64" r="21" fill="#ffffff" stroke="#0b4884" stroke-width="1"/>
<circle cx="130" cy="57" r="7" fill="#1168bd"/>
<path d="M118,78 Q118,62 130,62 Q142,62 142,78 Z" fill="#1168bd"/>
<text x="130" y="105" text-anchor="middle" dominant-baseline="central" font-size="15" font-weight="600" fill="#ffffff">Dueño de la PYME</text>
<text x="130" y="128" text-anchor="middle" dominant-baseline="central" font-size="12" fill="#d6e6f8">Rol: Administrador</text>

<!-- Vendedor -->
<rect x="30" y="190" width="200" height="130" rx="10" fill="#1168bd" stroke="#0b4884" stroke-width="1"/>
<circle cx="130" cy="224" r="21" fill="#ffffff" stroke="#0b4884" stroke-width="1"/>
<circle cx="130" cy="217" r="7" fill="#1168bd"/>
<path d="M118,238 Q118,222 130,222 Q142,222 142,238 Z" fill="#1168bd"/>
<text x="130" y="265" text-anchor="middle" dominant-baseline="central" font-size="15" font-weight="600" fill="#ffffff">Vendedor</text>
<text x="130" y="288" text-anchor="middle" dominant-baseline="central" font-size="12" fill="#d6e6f8">Rol: Operador de Ventas</text>

<!-- Empleado de bodega -->
<rect x="30" y="350" width="200" height="130" rx="10" fill="#1168bd" stroke="#0b4884" stroke-width="1"/>
<circle cx="130" cy="384" r="21" fill="#ffffff" stroke="#0b4884" stroke-width="1"/>
<circle cx="130" cy="377" r="7" fill="#1168bd"/>
<path d="M118,398 Q118,382 130,382 Q142,382 142,398 Z" fill="#1168bd"/>
<text x="130" y="425" text-anchor="middle" dominant-baseline="central" font-size="15" font-weight="600" fill="#ffffff">Empleado de bodega</text>
<text x="130" y="448" text-anchor="middle" dominant-baseline="central" font-size="12" fill="#d6e6f8">Rol: Operador de Inventario</text>

<!-- InvenTrack -->
<rect x="280" y="190" width="180" height="130" rx="10" fill="#08427b" stroke="#052e56" stroke-width="1"/>
<circle cx="370" cy="224" r="21" fill="#ffffff" stroke="#052e56" stroke-width="1"/>
<rect x="357" y="214" width="26" height="17" rx="2" fill="none" stroke="#08427b" stroke-width="2.2"/>
<rect x="366" y="231" width="8" height="4" fill="#08427b"/>
<line x1="361" y1="235" x2="379" y2="235" stroke="#08427b" stroke-width="2.2" stroke-linecap="round"/>
<text x="370" y="265" text-anchor="middle" dominant-baseline="central" font-size="15" font-weight="600" fill="#ffffff">InvenTrack</text>
<text x="370" y="288" text-anchor="middle" dominant-baseline="central" font-size="12" fill="#cfe0f0">Gestión de inventario</text>

<!-- Notificaciones -->
<rect x="490" y="190" width="150" height="130" rx="10" fill="#999999" stroke="#6b6b6b" stroke-width="1"/>
<circle cx="565" cy="224" r="21" fill="#ffffff" stroke="#6b6b6b" stroke-width="1"/>
<rect x="552" y="216" width="26" height="18" rx="2" fill="none" stroke="#5a5a5a" stroke-width="2.2"/>
<path d="M552,216 L565,228 L578,216" fill="none" stroke="#5a5a5a" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
<text x="565" y="265" text-anchor="middle" dominant-baseline="central" font-size="15" font-weight="600" fill="#ffffff">Notificaciones</text>
<text x="565" y="288" text-anchor="middle" dominant-baseline="central" font-size="12" fill="#eeeeee">Vía correo</text>

<!-- Bandeja -->
<rect x="490" y="350" width="150" height="100" rx="10" fill="#999999" stroke="#6b6b6b" stroke-width="1"/>
<circle cx="565" cy="382" r="18" fill="#ffffff" stroke="#6b6b6b" stroke-width="1"/>
<path d="M553,375 L553,384 L560,391 L570,391 L577,384 L577,375" fill="none" stroke="#5a5a5a" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
<line x1="553" y1="380" x2="577" y2="380" stroke="#5a5a5a" stroke-width="2.2"/>
<text x="565" y="418" text-anchor="middle" dominant-baseline="central" font-size="15" font-weight="600" fill="#ffffff">Bandeja</text>
<text x="565" y="438" text-anchor="middle" dominant-baseline="central" font-size="12" fill="#eeeeee">Endpoint final</text>

<!-- Flechas -->
<line x1="230" y1="95" x2="278" y2="205" stroke="#555555" stroke-width="1.5" marker-end="url(#arrow)"/>
<line x1="230" y1="255" x2="278" y2="255" stroke="#555555" stroke-width="1.5" marker-end="url(#arrow)"/>
<line x1="230" y1="415" x2="278" y2="270" stroke="#555555" stroke-width="1.5" marker-end="url(#arrow)"/>
<line x1="460" y1="255" x2="488" y2="255" stroke="#555555" stroke-width="1.5" marker-end="url(#arrow)"/>
<line x1="565" y1="320" x2="565" y2="348" stroke="#555555" stroke-width="1.5" marker-end="url(#arrow)"/>

<text x="242" y="150" font-size="12" fill="#555555">HTTPS</text>
<text x="242" y="245" font-size="12" fill="#555555">HTTPS</text>
<text x="242" y="350" font-size="12" fill="#555555">HTTPS</text>
<text x="474" y="245" text-anchor="middle" font-size="12" fill="#555555">SMTP</text>
<text x="565" y="336" text-anchor="middle" font-size="12" fill="#555555">entrega</text>

<!-- Leyenda -->
<line x1="30" y1="505" x2="640" y2="505" stroke="#dddddd" stroke-width="1"/>
<text x="30" y="525" font-size="14" font-weight="700" fill="#1a1a1a">Leyenda</text>

<circle cx="46" cy="548" r="12" fill="#1168bd" stroke="#0b4884" stroke-width="1"/>
<circle cx="46" cy="544" r="4" fill="#ffffff"/>
<path d="M40,553 Q40,547 46,547 Q52,547 52,553 Z" fill="#ffffff"/>
<text x="66" y="553" font-size="12" fill="#333333">Persona (actor humano)</text>

<circle cx="290" cy="548" r="12" fill="#08427b" stroke="#052e56" stroke-width="1"/>
<rect x="284" y="542" width="12" height="8" rx="1" fill="none" stroke="#ffffff" stroke-width="1.4"/>
<text x="310" y="553" font-size="12" fill="#333333">Sistema (InvenTrack)</text>

<circle cx="500" cy="548" r="12" fill="#999999" stroke="#6b6b6b" stroke-width="1"/>
<rect x="494" y="543" width="12" height="8" rx="1" fill="none" stroke="#ffffff" stroke-width="1.4"/>
<path d="M494,543 L500,548 L506,543" fill="none" stroke="#ffffff" stroke-width="1.4"/>
<text x="520" y="553" font-size="12" fill="#333333">Externo (fuera de nuestro control)</text>

</svg>
```

## Leyenda

| Color | Hex | Significado |
|---|---|---|
| Azul medio | `#1168bd` | **Persona** — actor humano que usa el sistema |
| Azul oscuro | `#08427b` | **Sistema** — InvenTrack, el proyecto que estamos documentando |
| Gris | `#999999` | **Externo** — sistema o endpoint fuera de nuestro control |

> **Nota sobre la convención de color:** el estándar original del modelo
> C4 (Simon Brown / Structurizr) usa persona en azul oscuro y sistema en
> azul medio. Aquí se invierte a pedido del curso, para que el sistema en
> desarrollo (InvenTrack) resalte visualmente como protagonista del
> diagrama.

## Roles y actores, explicados uno por uno

| Actor | Tipo | Rol en el sistema | Qué hace | Por qué está en el diagrama |
|---|---|---|---|---|
| Dueño de la PYME | Persona | **Administrador** | Gestiona usuarios, proveedores y catálogo de productos; consulta reportes e historial completo de movimientos. | Es el interesado principal (ver Stakeholders en el arc42): sin su rol, no habría razón de negocio para el sistema. |
| Vendedor | Persona | **Operador de Ventas** | Registra salidas de inventario por venta; consulta stock actual. | Dispara el escenario de mayor prioridad del proyecto (ESC-01): dos operadores registrando salidas al mismo tiempo es la situación que pone a prueba la Consistencia de datos. |
| Empleado de bodega | Persona | **Operador de Inventario** | Registra entradas de mercancía y ajustes de inventario. | Junto con Vendedor, es el segundo actor que puede generar concurrencia sobre el mismo producto (ESC-01), y es quien opera físicamente el almacén. |
| InvenTrack | Sistema (este proyecto) | — | Centraliza productos, proveedores, movimientos de inventario, usuarios y alertas de stock bajo. | Es el sistema que se está documentando; en este nivel se trata como caja cerrada a propósito. |
| Notificaciones | Sistema externo | — | Recibe la solicitud de alerta cuando un producto baja del umbral crítico y la entrega por correo electrónico. | Es el único sistema externo real del MVP: sin él, la funcionalidad "alertas de stock bajo" (declarada en el alcance de la ficha del problema) no se podría entregar. |
| Bandeja | Endpoint | — | Bandeja de correo donde finalmente llega la alerta (del Dueño, Vendedor o Empleado, según a quién se configure notificar). | Cierra el ciclo de la notificación: sin este endpoint, "Notificaciones" quedaría como una caja que solo recibe, sin mostrar a dónde entrega. |

**Por qué tres roles y no solo "Dueño" y "Empleado":** el escenario ESC-05
(control de acceso por rol, en la sección Quality Requirements del arc42)
exige verificar permisos sobre roles específicos. Con solo dos actores
genéricos, "Dueño" y "Administrador" terminaban confundiéndose como si
fueran roles distintos sin serlo realmente. Separar Vendedor y Empleado
de bodega, y nombrar el rol de cada uno explícitamente (Administrador,
Operador de Ventas, Operador de Inventario), elimina esa ambigüedad y
deja los tres roles de ESC-05 con un actor real detrás de cada uno.

## Por qué se eligieron esos protocolos en las flechas

- **HTTPS** entre las personas e InvenTrack: es el protocolo estándar para
  cualquier interfaz web, y es consistente con la restricción C5 (sin
  presupuesto para servicios de pago) — no requiere licencias ni
  infraestructura adicional. También conecta con la restricción C1 (Ley
  1581 de 2012): HTTPS cifra los datos en tránsito, protegiendo
  credenciales y datos personales.
- **SMTP** hacia Notificaciones: protocolo estándar de envío de correo;
  se mantiene simple porque la decisión de stack (y si se usa un
  proveedor transaccional con API propia en vez de SMTP directo) todavía
  está pendiente — se documentará como ADR cuando se decida.

## Qué falta y qué sigue

Este es solo el Nivel 1. Cuando el equipo decida el stack tecnológico
(ver "Stack de Desarrollo" en Inicio y orientación), este mismo archivo o
uno nuevo (`docs/c4/containers.md`) documentará el **Nivel 2: Contenedores**
— por ejemplo, si InvenTrack se divide en un frontend web, una API backend
y una base de datos, cada uno sería un contenedor separado dentro de la
caja que hoy aparece como una sola unidad.