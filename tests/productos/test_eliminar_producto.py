import pytest

from app.productos.application.crear_producto import CrearProducto
from app.productos.application.eliminar_producto import EliminarProducto
from app.productos.domain.exceptions import ProductoNoEncontrado
from app.productos.infrastructure.in_memory_repository import InMemoryProductoRepository
from app.productos.infrastructure.in_memory_verificador_movimientos import (
    InMemoryVerificadorDeMovimientos,
)


@pytest.fixture
def repositorio():
    return InMemoryProductoRepository()


@pytest.fixture
def verificador():
    return InMemoryVerificadorDeMovimientos()


def test_eliminar_producto_sin_movimientos_lo_borra_fisicamente(repositorio, verificador):
    CrearProducto(repositorio).ejecutar("p1", "Arroz 500g")

    resultado = EliminarProducto(repositorio, verificador).ejecutar("p1")

    assert resultado.eliminado_fisicamente is True
    assert resultado.desactivado is False
    assert repositorio.obtener("p1") is None


def test_eliminar_producto_con_movimientos_lo_desactiva_en_vez_de_borrar(repositorio, verificador):
    CrearProducto(repositorio).ejecutar("p2", "Aceite 1L")
    verificador.marcar_con_movimientos("p2")

    resultado = EliminarProducto(repositorio, verificador).ejecutar("p2")

    assert resultado.eliminado_fisicamente is False
    assert resultado.desactivado is True

    producto = repositorio.obtener("p2")
    assert producto is not None
    assert producto.activo is False


def test_eliminar_producto_inexistente_lanza_error(repositorio, verificador):
    with pytest.raises(ProductoNoEncontrado):
        EliminarProducto(repositorio, verificador).ejecutar("no-existe")
