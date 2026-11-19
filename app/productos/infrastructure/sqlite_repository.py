from app.productos.domain.ports import ProductoRepository
from app.productos.domain.producto import Producto
from app.shared.infrastructure.sqlite import conexion


class ProductosSQLite(ProductoRepository):
    def listar(self):
        filas = conexion.get().execute("SELECT id,nombre,activo FROM productos ORDER BY rowid")
        return [Producto(i, n, bool(a)) for i, n, a in filas]

    def obtener(self, producto_id):
        fila = conexion.get().execute("SELECT id,nombre,activo FROM productos WHERE id=?", (producto_id,)).fetchone()
        return Producto(fila[0], fila[1], bool(fila[2])) if fila else None

    def guardar(self, producto):
        conexion.get().execute(
            "INSERT INTO productos VALUES(?,?,?) ON CONFLICT(id) DO UPDATE SET nombre=excluded.nombre, activo=excluded.activo",
            (producto.id, producto.nombre, producto.activo),
        )

    def eliminar(self, producto_id):
        conexion.get().execute("DELETE FROM productos WHERE id=?", (producto_id,))
