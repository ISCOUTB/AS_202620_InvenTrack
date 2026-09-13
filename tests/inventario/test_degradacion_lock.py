import asyncio

import pytest

from app.inventario.application.registrar_movimiento import RegistrarMovimientoInventario
from app.inventario.domain.exceptions_producto import TiempoDeEsperaLockAgotado
from app.inventario.domain.ports import ValidadorDeProducto
from app.inventario.infrastructure.in_memory_movimiento_repository import (
    InMemoryMovimientoRepository,
)
from app.inventario.infrastructure.in_memory_repository import InMemoryStockRepository


class ValidadorDeProductoSiempreValido(ValidadorDeProducto):
    def existe_y_esta_activo(self, producto_id: str) -> bool:
        return True


@pytest.mark.asyncio
async def test_degrada_con_error_controlado_si_el_lock_no_se_libera_a_tiempo():
    
    registro = RegistrarMovimientoInventario(
        InMemoryStockRepository(),
        InMemoryMovimientoRepository(),
        ValidadorDeProductoSiempreValido(),
        lock_timeout_segundos=0.05,
    )

    # Se toma el lock del producto manualmente y nunca se libera dentro de
    # la ventana de la prueba, forzando el timeout de la segunda petición.
    lock = registro._locks["p-lento"]
    await lock.acquire()
    try:
        with pytest.raises(TiempoDeEsperaLockAgotado):
            await registro.registrar_entrada("p-lento", 1)
    finally:
        lock.release()
