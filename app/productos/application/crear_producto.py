from app.productos.domain.exceptions import ProductoYaExiste
from app.productos.domain.producto import Producto
from app.productos.domain.ports import ProductoRepository


class CrearProducto:
    def __init__(self, repositorio: ProductoRepository):
        self._repositorio = repositorio

    def ejecutar(self, producto_id: str, nombre: str) -> Producto:
        producto_existente = self._repositorio.obtener(producto_id)
        if producto_existente is not None:
            raise ProductoYaExiste(producto_id)

        producto = Producto(id=producto_id, nombre=nombre, activo=True)
        self._repositorio.guardar(producto)
        return producto
