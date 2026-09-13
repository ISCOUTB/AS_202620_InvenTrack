from app.inventario.application.consultar_movimientos import ConsultarHistorialMovimientos
from app.productos.domain.ports import VerificadorDeMovimientos


class HistorialMovimientosAdapter(VerificadorDeMovimientos):

    def __init__(self, consultar_historial: ConsultarHistorialMovimientos):
        self._consultar_historial = consultar_historial

    def tiene_movimientos_asociados(self, producto_id: str) -> bool:
        return self._consultar_historial.tiene_movimientos(producto_id)
