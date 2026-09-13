# Tabla de Propiedad de Datos — InvenTrack

**Principio de Arquitectura:** Regla de dueño único (Single Ownership). Cada entidad del sistema tiene un único módulo responsable de autorizar y ejecutar escrituras. Los demás contextos consumen datos únicamente vía puertos de aplicación o interfaces expuestas (`ADR-0001`, `ADR-0003`).

---

| Entidad / Datos | Módulo Dueño Único (Escritor) | Módulos Lectores (Solo Lectura) | Operaciones de Escritura Permitidas | Canal de Consulta Externa (Puertos) |
| :--- | :--- | :--- | :--- | :--- |
| **`Producto`** (id, nombre, activo) | `app/productos` | `app/inventario` | Crear producto, actualizar estado, desactivar. | Puerto `ConsultarProducto` (vía `ValidadorDeProductoAdapter`) |
| **`StockProducto`** (producto_id, cantidad) | `app/inventario` | `app/alertas`, Frontend | Actualizar saldo con lock por SKU (`ADR-0002`). | API / Caso de uso de lectura |
| **`Movimiento`** (historial de entradas/salidas) | `app/inventario` | `app/productos` | Registrar movimiento (Inmutable, solo INSERT). | Puerto `ConsultarHistorialMovimientos` (vía `HistorialMovimientosAdapter`) |
| **`Usuario`** (roles, credenciales) | `app/usuarios` *(por implementar)* | Todos los módulos | Crear usuario, modificar roles. | Middleware de Autenticación |