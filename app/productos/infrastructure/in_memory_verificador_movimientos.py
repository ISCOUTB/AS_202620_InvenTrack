from app.productos.domain.ports import VerificadorDeMovimientos


class InMemoryVerificadorDeMovimientos(VerificadorDeMovimientos):
    def __init__(self):
        self._productos_con_movimientos: set[str] = set()

    def marcar_con_movimientos(self, producto_id: str) -> None:
        self._productos_con_movimientos.add(producto_id)

    def tiene_movimientos_asociados(self, producto_id: str) -> bool:
        return producto_id in self._productos_con_movimientos
