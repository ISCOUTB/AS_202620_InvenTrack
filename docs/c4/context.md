# C4 Nivel 1 — Diagrama de Contexto — InvenTrack

```mermaid
C4Context
    title Diagrama de contexto del sistema — InvenTrack

    Person(dueno, "Dueño de la PYME", "Consulta inventario, reportes e historial; gestiona usuarios y proveedores")
    Person(empleado, "Empleado / Vendedor", "Registra entradas y salidas; consulta stock actual")

    System(inventrack, "InvenTrack", "Centraliza productos, proveedores, movimientos de inventario, usuarios y alertas de stock bajo")

    System_Ext(notificaciones, "Servicio de notificaciones", "Correo electrónico: entrega alertas de stock bajo")

    Rel(dueno, inventrack, "Usa", "HTTPS")
    Rel(empleado, inventrack, "Usa", "HTTPS")
    Rel(inventrack, notificaciones, "Envía alerta de stock bajo", "SMTP / API")
```

**Nota:** el Proveedor es un interesado indirecto: sus datos (catálogo,
órdenes) los ingresan manualmente el Dueño o el Empleado dentro de
InvenTrack; no hay integración directa con sistemas de proveedores en el
MVP, por lo que no aparece como actor externo en este diagrama de contexto.
