from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.inventario.application.registrar_movimiento import RegistrarMovimientoInventario
from app.inventario.domain.exceptions import ProductoSinStockError, StockInsuficienteError
from app.inventario.domain.exceptions_producto import ProductoInvalidoError, TiempoDeEsperaLockAgotado
from app.inventario.domain.ports import StockRepository


class MovimientoRequest(BaseModel):
    cantidad: int


class MovimientoResponse(BaseModel):
    producto_id: str
    cantidad: int
    tipo: str
    stock_final: int


def crear_router(registro: RegistrarMovimientoInventario, repositorio_stock: StockRepository) -> APIRouter:

    router = APIRouter()

    @router.post("/inventario/{producto_id}/entradas", response_model=MovimientoResponse)
    async def registrar_entrada(producto_id: str, payload: MovimientoRequest) -> MovimientoResponse:
        try:
            resultado = await registro.registrar_entrada(producto_id, payload.cantidad)
        except ProductoInvalidoError as exc:
            raise HTTPException(status_code=404, detail=str(exc)) from exc
        except TiempoDeEsperaLockAgotado as exc:
            raise HTTPException(status_code=503, detail=str(exc)) from exc
        return MovimientoResponse(**resultado.__dict__)

    @router.post("/inventario/{producto_id}/salidas", response_model=MovimientoResponse)
    async def registrar_salida(producto_id: str, payload: MovimientoRequest) -> MovimientoResponse:
        try:
            resultado = await registro.registrar_salida(producto_id, payload.cantidad)
        except ProductoInvalidoError as exc:
            raise HTTPException(status_code=404, detail=str(exc)) from exc
        except ProductoSinStockError as exc:
            raise HTTPException(status_code=404, detail=str(exc)) from exc
        except StockInsuficienteError as exc:
            raise HTTPException(status_code=409, detail=str(exc)) from exc
        except TiempoDeEsperaLockAgotado as exc:
            raise HTTPException(status_code=503, detail=str(exc)) from exc

        return MovimientoResponse(**resultado.__dict__)

    @router.get("/inventario/{producto_id}")
    def consultar_stock(producto_id: str) -> dict:
        stock = repositorio_stock.obtener(producto_id)
        if stock is None:
            raise HTTPException(status_code=404, detail="Producto sin stock registrado")
        return {"producto_id": stock.producto_id, "cantidad": stock.cantidad}

    return router
