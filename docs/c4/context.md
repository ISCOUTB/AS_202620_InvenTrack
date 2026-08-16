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
flowchart TB
    Dueno["Dueño de la PYME
    Persona
    Consulta inventario, reportes e
    historial; gestiona usuarios
    y proveedores"]

    Empleado["Empleado / Vendedor
    Persona
    Registra entradas y salidas;
    consulta stock actual"]

    InvenTrack["InvenTrack
    Sistema de software
    Centraliza productos, proveedores,
    movimientos de inventario, usuarios
    y alertas de stock bajo"]

    Notif["Servicio de notificaciones
    Sistema externo
    Correo electrónico: entrega
    alertas de stock bajo"]

    Dueno -- "Usa (HTTPS)" --> InvenTrack
    Empleado -- "Usa (HTTPS)" --> InvenTrack
    InvenTrack -- "Envía alerta de stock bajo (SMTP / API)" --> Notif

    classDef person fill:#1168bd,stroke:#0b4884,color:#ffffff,font-weight:bold
    classDef system fill:#0d3b66,stroke:#082746,color:#ffffff,font-weight:bold
    classDef external fill:#8a8a8a,stroke:#5c5c5c,color:#ffffff,font-weight:bold

    class Dueno,Empleado person
    class InvenTrack system
    class Notif external
```

**Leyenda:** azul claro = persona (actor humano), azul oscuro = el
sistema InvenTrack (lo que este proyecto construye), gris = sistema
externo (algo que ya existe, fuera del control del equipo).

## Actores y sistemas, explicados uno por uno

| Actor / sistema | Tipo | Interacción con InvenTrack | Por qué está en el diagrama |
|---|---|---|---|
| Dueño de la PYME | Persona | Consulta inventario, reportes e historial de movimientos; gestiona usuarios y proveedores. | Es el interesado principal (ver Stakeholders en el arc42): sin su rol, no habría razón de negocio para el sistema. |
| Empleado / vendedor | Persona | Registra entradas y salidas de mercancía; consulta stock actual. | Es quien dispara el escenario de mayor prioridad del proyecto (ESC-01): dos empleados operando al mismo tiempo es justamente la situación que pone a prueba la Consistencia de datos. |
| InvenTrack | Sistema (este proyecto) | Centraliza productos, proveedores, movimientos de inventario, usuarios y alertas de stock bajo. | Es el sistema que se está documentando; en este nivel se trata como caja cerrada a propósito. |
| Servicio de notificaciones (correo electrónico) | Sistema externo | Recibe la solicitud de alerta cuando un producto baja del umbral crítico y la entrega al destinatario. | Es el único sistema externo real del MVP: sin él, la funcionalidad "alertas de stock bajo" (declarada en el alcance de la ficha del problema) no se podría entregar. |

## Por qué se eligieron esos protocolos en las flechas

- **HTTPS** entre las personas e InvenTrack: es el protocolo estándar para
  cualquier interfaz web, y es consistente con la restricción C5 (sin
  presupuesto para servicios de pago) — no requiere licencias ni
  infraestructura adicional.
- **SMTP / API** hacia el servicio de notificaciones: se dejan ambas
  opciones abiertas a propósito, porque todavía no se ha decidido si el
  envío de correos se hace directo por SMTP o a través de la API de un
  proveedor de correo transaccional. Esa decisión se tomará junto con el
  stack técnico y quedará registrada como ADR.

## Por qué el Proveedor no aparece como actor externo

El Proveedor es un interesado real (está en la tabla de Stakeholders del
arc42), pero **no interactúa directamente con el sistema**: sus datos
(catálogo, órdenes) los ingresan manualmente el Dueño o el Empleado dentro
de InvenTrack. No hay integración directa con sistemas de proveedores en
el MVP — por eso, aunque el Proveedor le importa al negocio, no aparece
como caja en un diagrama de *contexto del sistema*, porque ese diagrama
solo dibuja actores y sistemas que efectivamente se comunican con
InvenTrack.

## Qué falta y qué sigue

Este es solo el Nivel 1. Cuando el equipo decida el stack tecnológico
(ver "Stack de Desarrollo" en Inicio y orientación), este mismo archivo o
uno nuevo (`docs/c4/containers.md`) documentará el **Nivel 2: Contenedores**
— por ejemplo, si InvenTrack se divide en un frontend web, una API backend
y una base de datos, cada uno sería un contenedor separado dentro de la
caja que hoy aparece como una sola unidad.
