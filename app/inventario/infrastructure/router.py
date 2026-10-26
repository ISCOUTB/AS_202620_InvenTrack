from collections.abc import Awaitable, Callable
from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, BackgroundTasks, Header, HTTPException
from pydantic import BaseModel, Field

from app.inventario.application.registrar_movimiento import RegistrarMovimientoInventario
from app.inventario.domain.exceptions import ProductoSinStockError, StockInsuficienteError
from app.inventario.domain.exceptions_producto import ProductoInvalidoError, TiempoDeEsperaLockAgotado
from app.inventario.domain.ports import StockRepository
from app.messaging.broker_simulador import SimuladorBrokerMensajeria

NOT_FOUND_RESPONSE = {"description": "Not Found"}
BAD_REQUEST_RESPONSE = {"description": "Bad Request - Cantidad inválida"}
SERVICE_UNAVAILABLE_RESPONSE = {"description": "Service Unavailable"}
MOVIMIENTOS_TOPIC = "inventario.movimientos"

class MovimientoRequest(BaseModel):
    cantidad: int = Field(gt=0)


class MovimientoResponse(BaseModel):
    producto_id: str
    cantidad: int
    tipo: str
    stock_final: int


def _error_entrada(exc: Exception) -> HTTPException:
    if isinstance(exc, ProductoInvalidoError):
        return HTTPException(status_code=404, detail=str(exc))
    if isinstance(exc, ValueError):
        return HTTPException(status_code=400, detail=str(exc))
    return HTTPException(status_code=503, detail=str(exc))


def _error_salida(exc: Exception) -> HTTPException:
    if isinstance(exc, ProductoInvalidoError | ProductoSinStockError):
        return HTTPException(status_code=404, detail=str(exc))
    if isinstance(exc, StockInsuficienteError):
        return HTTPException(status_code=409, detail=str(exc))
    if isinstance(exc, ValueError):
        status_code = 409 if "excede el stock" in str(exc) else 400
        return HTTPException(status_code=status_code, detail=str(exc))
    return HTTPException(status_code=503, detail=str(exc))


def _crear_handler_entrada(
    registro: RegistrarMovimientoInventario,
    broker: SimuladorBrokerMensajeria,
    consumidor_auditoria: Callable[[dict], Awaitable[None]],
) -> Callable[[str, MovimientoRequest], Awaitable[MovimientoResponse]]:
    async def registrar_entrada(
        producto_id: str,
        payload: MovimientoRequest,
        background_tasks: BackgroundTasks,
        correlation_id: str | None = Header(default=None, alias="X-Correlation-ID"),
    ) -> MovimientoResponse:
        try:
            resultado = await registro.registrar_entrada(producto_id, payload.cantidad)
        except (ProductoInvalidoError, ValueError, TiempoDeEsperaLockAgotado) as exc:
            raise _error_entrada(exc) from exc
        respuesta = MovimientoResponse(**resultado.__dict__)
        background_tasks.add_task(
            broker.publicar,
            MOVIMIENTOS_TOPIC,
            _crear_evento(respuesta, correlation_id),
            consumidor_auditoria,
        )
        return respuesta

    return registrar_entrada


def _crear_handler_salida(
    registro: RegistrarMovimientoInventario,
    broker: SimuladorBrokerMensajeria,
    consumidor_auditoria: Callable[[dict], Awaitable[None]],
) -> Callable[[str, MovimientoRequest], Awaitable[MovimientoResponse]]:
    async def registrar_salida(
        producto_id: str,
        payload: MovimientoRequest,
        background_tasks: BackgroundTasks,
        correlation_id: str | None = Header(default=None, alias="X-Correlation-ID"),
    ) -> MovimientoResponse:
        try:
            resultado = await registro.registrar_salida(producto_id, payload.cantidad)
        except (
            ProductoInvalidoError,
            ProductoSinStockError,
            StockInsuficienteError,
            ValueError,
            TiempoDeEsperaLockAgotado,
        ) as exc:
            raise _error_salida(exc) from exc

        respuesta = MovimientoResponse(**resultado.__dict__)
        background_tasks.add_task(
            broker.publicar,
            MOVIMIENTOS_TOPIC,
            _crear_evento(respuesta, correlation_id),
            consumidor_auditoria,
        )
        return respuesta

    return registrar_salida


def _crear_handler_stock(
    repositorio_stock: StockRepository,
) -> Callable[[str], dict]:
    def consultar_stock(producto_id: str) -> dict:
        stock = repositorio_stock.obtener(producto_id)
        if stock is None:
            raise HTTPException(status_code=404, detail="Producto sin stock registrado")
        return {"producto_id": stock.producto_id, "cantidad": stock.cantidad}

    return consultar_stock


def _crear_evento(respuesta: MovimientoResponse, correlation_id: str | None) -> dict:
    event_id = str(uuid4())
    return {
        "event_id": event_id,
        "correlation_id": correlation_id or event_id,
        "idempotency_key": event_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "data": respuesta.model_dump(),
    }


def crear_router(
    registro: RegistrarMovimientoInventario,
    repositorio_stock: StockRepository,
    broker: SimuladorBrokerMensajeria | None = None,
    consumidor_auditoria: Callable[[dict], Awaitable[None]] | None = None,
) -> APIRouter:

    router = APIRouter()
    broker = broker or SimuladorBrokerMensajeria()
    consumidor_auditoria = consumidor_auditoria or _consumidor_auditoria_nulo

    router.add_api_route(
        "/inventario/{producto_id}/entradas",
        _crear_handler_entrada(registro, broker, consumidor_auditoria),
        methods=["POST"],
        responses={
            400: BAD_REQUEST_RESPONSE,
            404: NOT_FOUND_RESPONSE,
            503: SERVICE_UNAVAILABLE_RESPONSE,
        },
    )

    router.add_api_route(
        "/inventario/{producto_id}/salidas",
        _crear_handler_salida(registro, broker, consumidor_auditoria),
        methods=["POST"],
        responses={
            400: BAD_REQUEST_RESPONSE,
            404: NOT_FOUND_RESPONSE,
            409: {"description": "Conflict - Stock insuficiente"},
            503: SERVICE_UNAVAILABLE_RESPONSE,
        },
    )

    router.add_api_route(
        "/inventario/{producto_id}",
        _crear_handler_stock(repositorio_stock),
        methods=["GET"],
        responses={404: NOT_FOUND_RESPONSE},
    )

    return router


async def _consumidor_auditoria_nulo(message: dict) -> None:
    """Punto de extensión del consumidor de auditoría del MVP."""