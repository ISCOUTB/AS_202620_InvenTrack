# Tabla de Propiedad de Datos — InvenTrack

**Principio de Arquitectura:** Regla de dueño único (Single Ownership). Cada entidad o conjunto de datos dentro del sistema tiene exactamente un módulo responsable de autorizar y ejecutar sus escrituras. Ningún otro módulo puede modificar directamente tablas de un dominio ajeno; el acceso entre contextos se realiza estrictamente a través de puertos de aplicación o APIs expuestas (`ADR-0001`, `ADR-0003`).

---

## Matriz de Propiedad y Canales de Consulta

| Entidad / Datos | Módulo Dueño Único (Escritor) | Módulos Lectores (Solo Lectura) | Operaciones de Escritura Permitidas | Canal de Consulta Externa (Puertos) |
| :--- | :--- | :--- | :--- | :--- |
| **`Producto`** <br>*(id, nombre, activo)* | `app/productos` | `app/inventario` | Crear producto, actualizar datos, cambiar estado (activo/inactivo). | Puerto `ConsultarProducto` <br>*(vía `ValidadorDeProductoAdapter`)* |
| **`StockProducto`** <br>*(producto_id, cantidad)* | `app/inventario` | `app/alertas`, Frontend | Modificar saldo disponible aplicando control de concurrencia (`ADR-0002`). | API / Caso de uso de consulta de stock |
| **`Movimiento`** <br>*(historial de entradas y salidas)* | `app/inventario` | `app/productos`, Auditoría | Registrar movimientos de stock (Inmutable: solo escrituras `INSERT`). | Puerto `ConsultarHistorialMovimientos` <br>*(vía `HistorialMovimientosAdapter`)* |
| **`Usuario / Rol`** <br>*(id, rol, permisos)* | `app/usuarios` <br>*(declarado en ESC-05)* | Todos los módulos | Registrar usuario, modificar rol o estado de acceso. | Middleware / Token de Autenticación |
| **`AlertaStock`** <br>*(id, producto_id, resuelta)* | `app/alertas` <br>*(por implementar)* | Dashboard, Frontend | Generar alerta por umbral bajo, marcar como resuelta. | API / Endpoint de alertas activas |

---

## Justificación de Fronteras Técnicas

1. **Catálogo de Productos (`app/productos`):**
   * Controla la definición del bien o servicio. No conoce cuántas unidades físicas hay en almacén ni los registros de ventas/compras.
   * Expone el puerto `ConsultarProducto` para que `inventario` valide que un producto existe y está activo antes de procesar una entrada o salida.

2. **Inventario y Saldos (`app/inventario`):**
   * Controla de manera exclusiva la cantidad física disponible (`StockProducto`) y el registro de auditoría (`Movimiento`).
   * Aplica un mecanismo de exclusión mutua por SKU (`asyncio.Lock` / `ADR-0002`) para asegurar consistencia ante llamadas concurrentes.
   * Expone el puerto `ConsultarHistorialMovimientos` para que `productos` verifique si el ítem tiene transacciones activas antes de permitir su eliminación (`ESC-02`).