import pytest

from app.inventario.application.registrar_movimiento import RegistrarMovimientoInventario
from app.inventario.domain.exceptions_producto import ProductoInvalidoError
from app.inventario.domain.ports import ValidadorDeProducto
from app.inventario.infrastructure.in_memory_movimiento_repository import (
    InMemoryMovimientoRepository,
)
from app.inventario.infrastructure.in_memory_repository import InMemoryStockRepository


class ValidadorDeProductoFalso(ValidadorDeProducto):

    def __init__(self, existe: bool):
        self._existe = existe

    def existe_y_esta_activo(self, producto_id: str) -> bool:
        return self._existe


@pytest.mark.asyncio
async def test_no_registra_movimiento_si_producto_no_existe_o_esta_inactivo():
    registro = RegistrarMovimientoInventario(
        InMemoryStockRepository(),
        InMemoryMovimientoRepository(),
        ValidadorDeProductoFalso(existe=False),
    )

    with pytest.raises(ProductoInvalidoError):
        await registro.registrar_entrada("no-existe", 10)


@pytest.mark.asyncio
async def test_registra_movimiento_si_el_producto_existe_y_esta_activo():
    registro = RegistrarMovimientoInventario(
        InMemoryStockRepository(),
        InMemoryMovimientoRepository(),
        ValidadorDeProductoFalso(existe=True),
    )

    resultado = await registro.registrar_entrada("p-1", 10)

    assert resultado.stock_final == 10
