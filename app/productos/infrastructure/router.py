from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.productos.application.crear_producto import CrearProducto
from app.productos.application.eliminar_producto import EliminarProducto
from app.productos.domain.exceptions import ProductoNoEncontrado


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


def crear_router(crear_producto: CrearProducto, eliminar_producto: EliminarProducto) -> APIRouter:

    router = APIRouter()

    @router.post("/productos", status_code=201)
    def crear(payload: CrearProductoRequest) -> ProductoResponse:
        producto = crear_producto.ejecutar(payload.id, payload.nombre)
        return ProductoResponse(id=producto.id, nombre=producto.nombre, activo=producto.activo)

    @router.delete(
        "/productos/{producto_id}",
        response_model=EliminarProductoResponse,
        responses={404: {"description": "Not Found"}},
    )
    def eliminar(producto_id: str) -> EliminarProductoResponse:
        try:
            resultado = eliminar_producto.ejecutar(producto_id)
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

    return router
