from abc import ABC, abstractmethod

from app.productos.domain.producto import Producto


class ProductoRepository(ABC):
    @abstractmethod
    def obtener(self, producto_id: str) -> Producto | None:
        raise NotImplementedError

    @abstractmethod
    def guardar(self, producto: Producto) -> None:
        raise NotImplementedError

    @abstractmethod
    def eliminar(self, producto_id: str) -> None:
        raise NotImplementedError


class VerificadorDeMovimientos(ABC):
    @abstractmethod
    def tiene_movimientos_asociados(self, producto_id: str) -> bool:
        raise NotImplementedError
