from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.inventario.application.registrar_movimiento import RegistrarMovimientoInventario
from app.inventario.domain.exceptions import ProductoSinStockError, StockInsuficienteError
from app.inventario.infrastructure.in_memory_repository import InMemoryStockRepository

router = APIRouter()

_repositorio = InMemoryStockRepository()
_registro = RegistrarMovimientoInventario(_repositorio)


class MovimientoRequest(BaseModel):
    cantidad: int


class MovimientoResponse(BaseModel):
    producto_id: str
    cantidad: int
    tipo: str
    stock_final: int


@router.post("/inventario/{producto_id}/entradas", response_model=MovimientoResponse)
def registrar_entrada(producto_id: str, payload: MovimientoRequest) -> MovimientoResponse:
    resultado = _registro.registrar_entrada(producto_id, payload.cantidad)
    return MovimientoResponse(**resultado.__dict__)


@router.post("/inventario/{producto_id}/salidas", response_model=MovimientoResponse)
def registrar_salida(producto_id: str, payload: MovimientoRequest) -> MovimientoResponse:
    try:
        resultado = _registro.registrar_salida(producto_id, payload.cantidad)
    except ProductoSinStockError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except StockInsuficienteError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc

    return MovimientoResponse(**resultado.__dict__)


@router.get("/inventario/{producto_id}")
def consultar_stock(producto_id: str) -> dict:
    stock = _repositorio.obtener(producto_id)
    if stock is None:
        raise HTTPException(status_code=404, detail="Producto sin stock registrado")
    return {"producto_id": stock.producto_id, "cantidad": stock.cantidad}
