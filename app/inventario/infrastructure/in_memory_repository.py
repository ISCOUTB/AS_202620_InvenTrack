from app.inventario.domain.ports import StockRepository
from app.inventario.domain.stock import StockProducto


class InMemoryStockRepository(StockRepository):
    def __init__(self):
        self._stock: dict[str, StockProducto] = {}

    def obtener(self, producto_id: str) -> StockProducto | None:
        return self._stock.get(producto_id)

    def guardar(self, stock: StockProducto) -> None:
        self._stock[stock.producto_id] = stock

    def listar(self) -> list[StockProducto]:
        return list(self._stock.values())
