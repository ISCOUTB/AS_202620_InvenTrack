# Tabla de Propiedad de Datos — InvenTrack

**Actualización posterior a S15.** El perfil durable añade un usuario y un rol por credencial, 401/403 en las rutas de negocio y persistencia transaccional de catálogo, stock, historial y auditoría con actor. Producción cerrada conserva el 503 preventivo. Las observaciones previas corresponden al perfil inicial. [ADR-0019](./adr/0019-autenticar-usuarios-y-autorizar-por-rol.md) · [ADR-0020](./adr/0020-persistir-inventario-y-auditoria-en-sqlite.md) · [verificación](./verificacion-final.md).

**Principio de Arquitectura:** Regla de dueño único (Single Ownership). Cada entidad o conjunto de datos dentro del sistema tiene exactamente un módulo responsable de autorizar y ejecutar sus escrituras. Ningún otro módulo puede modificar directamente tablas de un dominio ajeno; el acceso entre contextos se realiza estrictamente a través de puertos de aplicación o APIs expuestas (`ADR-0001`, `ADR-0003`). En el MVP, los repositorios son en memoria; `ADR-0012` establece que una futura persistencia durable debe conservar estas mismas fronteras.

---

## Matriz de Propiedad y Canales de Consulta

| Entidad / Datos | Módulo Dueño Único (Escritor) | Módulos Lectores (Solo Lectura) | Operaciones de Escritura Permitidas | Canal de Consulta Externa (Puertos) |
| :--- | :--- | :--- | :--- | :--- |
| **`Producto`** <br>*(id, nombre, activo)* | `app/productos` | `app/inventario`, Frontend *(respuesta de sesión vía API)* | Crear producto, actualizar datos, cambiar estado (activo/inactivo). | Puerto `ConsultarProducto` <br>*(vía `ValidadorDeProductoAdapter`)* y endpoints `POST /productos`, `DELETE /productos/{id}` |
| **`StockProducto`** <br>*(producto_id, cantidad)* | `app/inventario` | `app/alertas`, Frontend | Modificar saldo disponible aplicando control de concurrencia (`ADR-0002`). | API / Caso de uso de consulta de stock |
| **`Movimiento`** <br>*(historial de entradas y salidas)* | `app/inventario` | `app/productos`, Auditoría | Registrar movimientos de stock (Inmutable: solo escrituras `INSERT`). | Puerto `ConsultarHistorialMovimientos` <br>*(vía `HistorialMovimientosAdapter`)* |
| **`Usuario / Rol`** <br>*(id, rol, permisos)* | `app/usuarios` <br>*(declarado en ESC-05)* | Todos los módulos | Registrar usuario, modificar rol o estado de acceso. | Middleware / Token de Autenticación |
| **Correo de stock bajo** (evento, SKU, saldo, estado de envío) | `app/alertas` | Despachador SMTP | Encolar en la transacción de salida y registrar la entrega o el reintento. | Adaptador SMTP |
| **Proveedor** (id, nombre, contacto) | `app/proveedores` | Flutter | Crear, editar y eliminar proveedores. | `/proveedores` |
| **Corte de turno** (id, fecha, saldos) | `app/inventario` | Flutter | Guardar una instantánea de existencias para conciliación. | `/cierres` |

---

## Justificación de Fronteras Técnicas

1. **Catálogo de Productos (`app/productos`):**
   * Controla la definición del bien o servicio. No conoce cuántas unidades físicas hay en almacén ni los registros de ventas/compras.
   * Expone el puerto `ConsultarProducto` para que `inventario` valide que un producto existe y está activo antes de procesar una entrada o salida.

2. **Inventario y Saldos (`app/inventario`):**
   * Controla de manera exclusiva la cantidad física disponible (`StockProducto`) y el registro de auditoría (`Movimiento`).
   * Aplica un mecanismo de exclusión mutua por SKU (`asyncio.Lock` / `ADR-0002`) para asegurar consistencia ante llamadas concurrentes.
   * Expone el puerto `ConsultarHistorialMovimientos` para que `productos` verifique si el ítem tiene transacciones activas antes de permitir su eliminación (`ESC-02`).

## Persistencia y evolución

El perfil de demostración conserva el catálogo, existencias, movimientos, proveedores y cortes en memoria durante la vida del proceso. En SQLite estos datos se guardan en el volumen junto con identidades, registros idempotentes, auditoría y la cola de correo. El corte contiene los saldos obtenidos mediante los repositorios de productos e inventario. [Persistencia SQLite](adr/0020-persistir-inventario-y-auditoria-en-sqlite.md) · [cola de correo](adr/0022-entregar-alertas-de-stock-desde-sqlite.md).