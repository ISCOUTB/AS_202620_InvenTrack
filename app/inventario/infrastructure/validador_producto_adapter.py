from app.inventario.domain.ports import ValidadorDeProducto
from app.productos.application.consultar_producto import ConsultarProducto


class ValidadorDeProductoAdapter(ValidadorDeProducto):
    """Implementa el puerto ValidadorDeProducto de inventario invocando el
    caso de uso de aplicación de productos (ADR-0003). No importa el domain
    ni la infrastructure de productos, solo su application."""

    def __init__(self, consultar_producto: ConsultarProducto):
        self._consultar_producto = consultar_producto

    def existe_y_esta_activo(self, producto_id: str) -> bool:
        producto = self._consultar_producto.ejecutar(producto_id)
        return producto is not None and producto.activo
