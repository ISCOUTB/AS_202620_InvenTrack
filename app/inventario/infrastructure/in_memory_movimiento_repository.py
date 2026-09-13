from app.inventario.domain.movimiento import Movimiento
from app.inventario.domain.ports import MovimientoRepository


class InMemoryMovimientoRepository(MovimientoRepository):
    def __init__(self):
        self._movimientos: list[Movimiento] = []

    def registrar(self, movimiento: Movimiento) -> None:
        self._movimientos.append(movimiento)

    def tiene_movimientos(self, producto_id: str) -> bool:
        return any(m.producto_id == producto_id for m in self._movimientos)

    def listar_por_producto(self, producto_id: str) -> list[Movimiento]:
        return [m for m in self._movimientos if m.producto_id == producto_id]
