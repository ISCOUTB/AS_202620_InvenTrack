from dataclasses import dataclass

from app.inventario.domain.exceptions import ProductoSinStockError, StockInsuficienteError
from app.inventario.domain.ports import StockRepository
from app.inventario.domain.stock import StockProducto


@dataclass
class MovimientoInventarioResult:
    producto_id: str
    cantidad: int
    tipo: str
    stock_final: int


class RegistrarMovimientoInventario:
    def __init__(self, repositorio: StockRepository):
        self._repositorio = repositorio

    def registrar_entrada(self, producto_id: str, cantidad: int) -> MovimientoInventarioResult:
        stock = self._repositorio.obtener(producto_id)
        if stock is None:
            stock = StockProducto(producto_id=producto_id, cantidad=0)

        stock.registrar_entrada(cantidad)
        self._repositorio.guardar(stock)

        return MovimientoInventarioResult(
            producto_id=producto_id,
            cantidad=cantidad,
            tipo="entrada",
            stock_final=stock.cantidad,
        )

    def registrar_salida(self, producto_id: str, cantidad: int) -> MovimientoInventarioResult:
        stock = self._repositorio.obtener(producto_id)
        if stock is None:
            raise ProductoSinStockError(producto_id)

        if cantidad > stock.cantidad:
            raise StockInsuficienteError(producto_id, cantidad, stock.cantidad)

        stock.registrar_salida(cantidad)
        self._repositorio.guardar(stock)

        return MovimientoInventarioResult(
            producto_id=producto_id,
            cantidad=cantidad,
            tipo="salida",
            stock_final=stock.cantidad,
        )
