from app.productos.domain.producto import Producto
from app.productos.domain.ports import ProductoRepository


class InMemoryProductoRepository(ProductoRepository):
    def __init__(self):
        self._productos: dict[str, Producto] = {}

    def obtener(self, producto_id: str) -> Producto | None:
        return self._productos.get(producto_id)

    def guardar(self, producto: Producto) -> None:
        self._productos[producto.id] = producto

    def eliminar(self, producto_id: str) -> None:
        self._productos.pop(producto_id, None)
