from app.productos.domain.ports import ProductoRepository
from app.productos.domain.producto import Producto


class ConsultarProducto:

    def __init__(self, repositorio: ProductoRepository):
        self._repositorio = repositorio

    def ejecutar(self, producto_id: str) -> Producto | None:
        return self._repositorio.obtener(producto_id)
