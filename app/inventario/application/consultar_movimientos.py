from app.inventario.domain.ports import MovimientoRepository


class ConsultarHistorialMovimientos:

    def __init__(self, repositorio: MovimientoRepository):
        self._repositorio = repositorio

    def tiene_movimientos(self, producto_id: str) -> bool:
        return self._repositorio.tiene_movimientos(producto_id)
