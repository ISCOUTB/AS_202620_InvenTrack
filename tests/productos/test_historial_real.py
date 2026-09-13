from app.inventario.application.consultar_movimientos import ConsultarHistorialMovimientos
from app.inventario.domain.movimiento import Movimiento
from app.inventario.infrastructure.in_memory_movimiento_repository import (
    InMemoryMovimientoRepository,
)
from app.productos.infrastructure.historial_movimientos_adapter import (
    HistorialMovimientosAdapter,
)


def test_adaptador_refleja_movimientos_reales_de_inventario():
    """Antes del ADR-0003, este resultado dependía de un endpoint de
    prueba (_marcar-con-movimientos) que no tocaba inventario para nada.
    Ahora depende de un movimiento real registrado en ese módulo."""
    movimientos_repo = InMemoryMovimientoRepository()
    consultar_historial = ConsultarHistorialMovimientos(movimientos_repo)
    adaptador = HistorialMovimientosAdapter(consultar_historial)

    assert adaptador.tiene_movimientos_asociados("p-adr") is False

    movimientos_repo.registrar(Movimiento("p-adr", "entrada", 5))

    assert adaptador.tiene_movimientos_asociados("p-adr") is True
