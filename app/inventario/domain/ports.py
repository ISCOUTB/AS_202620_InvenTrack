from abc import ABC, abstractmethod

from app.inventario.domain.movimiento import Movimiento
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


class MovimientoRepository(ABC):
    @abstractmethod
    def registrar(self, movimiento: Movimiento) -> None:
        raise NotImplementedError

    @abstractmethod
    def tiene_movimientos(self, producto_id: str) -> bool:
        raise NotImplementedError

    @abstractmethod
    def listar_por_producto(self, producto_id: str) -> list[Movimiento]:
        raise NotImplementedError


class ValidadorDeProducto(ABC):

    @abstractmethod
    def existe_y_esta_activo(self, producto_id: str) -> bool:
        raise NotImplementedError
