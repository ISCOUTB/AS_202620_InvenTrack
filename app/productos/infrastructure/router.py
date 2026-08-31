from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.productos.application.crear_producto import CrearProducto
from app.productos.application.eliminar_producto import EliminarProducto
from app.productos.domain.exceptions import ProductoNoEncontrado
from app.productos.infrastructure.in_memory_repository import InMemoryProductoRepository
from app.productos.infrastructure.in_memory_verificador_movimientos import (
    InMemoryVerificadorDeMovimientos,
)

router = APIRouter()

_repositorio = InMemoryProductoRepository()
_verificador_movimientos = InMemoryVerificadorDeMovimientos()

_crear_producto = CrearProducto(_repositorio)
_eliminar_producto = EliminarProducto(_repositorio, _verificador_movimientos)


class CrearProductoRequest(BaseModel):
    id: str
    nombre: str


class ProductoResponse(BaseModel):
    id: str
    nombre: str
    activo: bool


class EliminarProductoResponse(BaseModel):
    eliminado_fisicamente: bool
    desactivado: bool
    mensaje: str


@router.post("/productos", response_model=ProductoResponse, status_code=201)
def crear_producto(payload: CrearProductoRequest) -> ProductoResponse:
    producto = _crear_producto.ejecutar(payload.id, payload.nombre)
    return ProductoResponse(id=producto.id, nombre=producto.nombre, activo=producto.activo)


@router.post("/productos/{producto_id}/_marcar-con-movimientos", status_code=204)
def marcar_con_movimientos_de_prueba(producto_id: str) -> None:
    _verificador_movimientos.marcar_con_movimientos(producto_id)


@router.delete("/productos/{producto_id}", response_model=EliminarProductoResponse)
def eliminar_producto(producto_id: str) -> EliminarProductoResponse:
    try:
        resultado = _eliminar_producto.ejecutar(producto_id)
    except ProductoNoEncontrado:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    if resultado.eliminado_fisicamente:
        mensaje = "Producto eliminado físicamente (no tenía movimientos asociados)."
    else:
        mensaje = (
            "Producto NO eliminado físicamente por tener movimientos asociados "
            "(ESC-02): se desactivó en su lugar (borrado lógico)."
        )

    return EliminarProductoResponse(
        eliminado_fisicamente=resultado.eliminado_fisicamente,
        desactivado=resultado.desactivado,
        mensaje=mensaje,
    )
