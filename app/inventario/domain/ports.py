from abc import ABC, abstractmethod

from app.inventario.domain.stock import StockProducto


class StockRepository(ABC):
    @abstractmethod
    def obtener(self, producto_id: str) -> StockProducto | None:
        raise NotImplementedError

    @abstractmethod
    def guardar(self, stock: StockProducto) -> None:
        raise NotImplementedError

    @abstractmethod
    def listar(self) -> list[StockProducto]:
        raise NotImplementedError
