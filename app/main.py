"""Punto de entrada de InvenTrack.

Este archivo es el composition root de la aplicación: construye los
repositorios, casos de uso y adaptadores de cada módulo, resuelve las
dependencias cruzadas entre módulos (ADR-0003) y ensambla los routers.
"""

import asyncio
import json
import logging
import math
import os
import secrets
import sqlite3
import time
from collections import defaultdict, deque
from collections.abc import Awaitable, Callable
from contextlib import asynccontextmanager, suppress

from fastapi import Depends, FastAPI, Request, Response
from fastapi.responses import JSONResponse
from fastapi.security import HTTPBearer
from starlette.middleware.base import BaseHTTPMiddleware

from app.inventario.application.consultar_movimientos import ConsultarHistorialMovimientos
from app.inventario.application.registrar_movimiento import RegistrarMovimientoInventario
from app.inventario.infrastructure.in_memory_movimiento_repository import (
    InMemoryMovimientoRepository,
)
from app.inventario.infrastructure.in_memory_repository import InMemoryStockRepository
from app.inventario.infrastructure.idempotency import InMemoryIdempotencyStore
from app.inventario.infrastructure.router import crear_router as crear_router_inventario
from app.inventario.infrastructure.validador_producto_adapter import ValidadorDeProductoAdapter
from app.messaging.broker_simulador import SimuladorBrokerMensajeria
from app.productos.application.consultar_producto import ConsultarProducto
from app.productos.application.crear_producto import CrearProducto
from app.productos.application.eliminar_producto import EliminarProducto
from app.productos.infrastructure.historial_movimientos_adapter import (
    HistorialMovimientosAdapter,
)
from app.productos.infrastructure.in_memory_repository import InMemoryProductoRepository
from app.productos.infrastructure.router import crear_router as crear_router_productos
from app.productos.infrastructure.sqlite_repository import ProductosSQLite
from app.inventario.infrastructure.sqlite_repository import IdempotenciaSQLite, MovimientosSQLite, StockSQLite, guardar_evento
from app.shared.infrastructure.sqlite import (
    EsperaEscrituraAgotada, actor, escritor_del_servicio, inicializar, transaccion,
)
from app.usuarios.infrastructure.credenciales import autenticar, permitido
from app.usuarios.infrastructure.router import router as router_usuarios
from app.proveedores.infrastructure.router import crear_router as crear_router_proveedores
from app.inventario.infrastructure.cierres import crear_router as crear_router_cierres
from app.inventario.domain.movimiento import Movimiento
from app.alertas.infrastructure.correo import correo_configurado, procesar_cola, registrar_cruce
from app.shared.infrastructure.sqlite import conexion


class JsonFormatter(logging.Formatter):
    """Format application logs as one JSON object per line."""

    def format(self, record: logging.LogRecord) -> str:
        return json.dumps(
            {
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "level": record.levelname,
                "logger": record.name,
                "message": record.getMessage(),
            },
            ensure_ascii=True,
        )


_http_logger = logging.getLogger("inventrack.http")
_http_logger.setLevel(logging.INFO)
if not _http_logger.handlers:
    _handler = logging.StreamHandler()
    _handler.setFormatter(JsonFormatter())
    _http_logger.addHandler(_handler)
_http_logger.propagate = False
_messaging_logger = logging.getLogger("InvenTrack.Messaging")
_messaging_logger.setLevel(logging.INFO)
if not _messaging_logger.handlers:
    _messaging_logger.addHandler(_handler)
_messaging_logger.propagate = False

_request_count: defaultdict[tuple[str, str], int] = defaultdict(int)
_request_duration_seconds: defaultdict[tuple[str, str], float] = defaultdict(float)
# Historial acotado para cálculo de p95 sin afectar la memoria ni crear ramas muertas
_request_durations_history: defaultdict[tuple[str, str], deque] = defaultdict(lambda: deque(maxlen=1000))


def _is_production() -> bool:
    return os.getenv("INVENTRACK_ENV", "development").lower() == "production"


def _internal_token_is_valid(request: Request) -> bool:
    expected_token = os.getenv("INVENTRACK_INTERNAL_TOKEN")
    provided = request.headers.get("X-Internal-Token", "")
    return bool(expected_token) and secrets.compare_digest(provided.encode(), expected_token.encode())


class AccessPolicyMiddleware(BaseHTTPMiddleware):
    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]],
    ) -> Response:
        if _is_production() and request.url.path in {
            "/metrics",
            "/docs",
            "/docs/oauth2-redirect",
            "/redoc",
            "/openapi.json",
        } and not _internal_token_is_valid(request):
            return Response(status_code=404)

        ruta = request.url.path
        recurso = ruta.split("/")[1]
        if recurso not in {"productos", "inventario", "usuarios", "sesion", "proveedores", "cierres"}:
            return await call_next(request)
        habilitado = os.getenv("INVENTRACK_ALLOW_BUSINESS_DATA", "false").lower() == "true"
        if _is_production() and not (_db_path and habilitado):
            return Response("Business data endpoints are disabled.", status_code=503)
        if not _db_path:
            if recurso == "usuarios":
                return JSONResponse({"detail": "La administración requiere el perfil autenticado"}, status_code=403)
            return await call_next(request)
        try:
            async with transaccion(_db_path, request.method != "GET") as db:
                usuario = autenticar(db, request.headers.get("Authorization", ""))
                if usuario is None:
                    return JSONResponse({"detail": "Credencial individual requerida"}, status_code=401,
                                        headers={"WWW-Authenticate": "Bearer"})
                identidad, rol = usuario
                if not permitido(rol, request.method, ruta):
                    return JSONResponse({"detail": "Permiso insuficiente"}, status_code=403)
                actor.set(identidad)
                respuesta = await call_next(request)
                if respuesta.status_code < 400:
                    db.commit()
                return respuesta
        except (EsperaEscrituraAgotada, sqlite3.OperationalError) as exc:
            if isinstance(exc, sqlite3.OperationalError) and getattr(exc, "sqlite_errorcode", None) not in (
                sqlite3.SQLITE_BUSY, sqlite3.SQLITE_LOCKED
            ):
                raise
            return Response(status_code=503, headers={"Retry-After": "1"})


class ObservabilityMiddleware(BaseHTTPMiddleware):
    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]],
    ) -> Response:
        started = time.perf_counter()
        response = await call_next(request)
        duration = time.perf_counter() - started
        key = (request.method, request.url.path)
        
        _request_count[key] += 1
        _request_duration_seconds[key] += duration
        _request_durations_history[key].append(duration)
        
        _http_logger.info(
            json.dumps(
                {
                    "event": "http_request",
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": response.status_code,
                    "duration_ms": round(duration * 1000, 3),
                },
                ensure_ascii=True,
            )
        )
        return response


def _prometheus_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def _p95_latency(history: list[float]) -> float:
    ordered = sorted(history)
    rank = max(1, math.ceil(len(ordered) * 0.95))
    return ordered[rank - 1]


# --- productos: repositorio y casos de uso propios ---
_db_path = os.getenv("INVENTRACK_DB_PATH")
if _db_path:
    inicializar(_db_path)
_productos_repo = ProductosSQLite() if _db_path else InMemoryProductoRepository()
_consultar_producto = ConsultarProducto(_productos_repo)
_crear_producto = CrearProducto(_productos_repo)

# --- inventario: repositorios y casos de uso propios ---
_stock_repo = StockSQLite() if _db_path else InMemoryStockRepository()
_movimientos_repo = MovimientosSQLite() if _db_path else InMemoryMovimientoRepository()
_consultar_historial = ConsultarHistorialMovimientos(_movimientos_repo)

# --- adaptadores cruzados (ADR-0003) ---
_validador_producto = ValidadorDeProductoAdapter(_consultar_producto)
_historial_movimientos = HistorialMovimientosAdapter(_consultar_historial)

# --- casos de uso que dependen de un adaptador cruzado ---
_eliminar_producto = EliminarProducto(_productos_repo, _historial_movimientos)
_registrar_movimiento = RegistrarMovimientoInventario(
    _stock_repo, _movimientos_repo, _validador_producto
)
_broker_mensajeria = SimuladorBrokerMensajeria()
_idempotency_store = IdempotenciaSQLite() if _db_path else InMemoryIdempotencyStore()


def _consumir_auditoria_movimiento(message: dict) -> None:
    _http_logger.info(
        json.dumps(
            {
                "event": "inventory_message_consumed",
                "event_id": message["event_id"],
                "correlation_id": message["correlation_id"],
                "topic": "inventario.movimientos",
            },
            ensure_ascii=True,
        )
    )

_production_without_internal_token = _is_production() and not os.getenv("INVENTRACK_INTERNAL_TOKEN")


@asynccontextmanager
async def _vida_api(_app):
    if not _db_path:
        yield
        return
    with escritor_del_servicio(_db_path):
        tarea = asyncio.create_task(procesar_cola(_db_path)) if correo_configurado() else None
        try:
            yield
        finally:
            if tarea is not None:
                tarea.cancel()
                with suppress(asyncio.CancelledError):
                    await tarea


app = FastAPI(
    title="InvenTrack",
    description="Sistema de gestión de inventarios para pequeñas empresas.",
    version="0.1.0",
    lifespan=_vida_api,
    docs_url=None if _production_without_internal_token else "/docs",
    redoc_url=None if _production_without_internal_token else "/redoc",
    openapi_url=None if _production_without_internal_token else "/openapi.json",
)
app.add_middleware(AccessPolicyMiddleware)
app.add_middleware(ObservabilityMiddleware)


@app.get("/health", tags=["infraestructura"])
def health_check() -> dict[str, str]:
    return {"status": "ok", "service": "InvenTrack"}


@app.get("/", include_in_schema=False, tags=["infraestructura"])
def root() -> dict[str, str]:
    response = {"service": "InvenTrack", "status": "ok", "health": "/health"}
    if app.docs_url:
        response["docs"] = app.docs_url
    return response


@app.get("/metrics", include_in_schema=False, tags=["infraestructura"], response_class=Response)
def metrics():
    lines = [
        "# HELP inventrack_http_requests_total Total HTTP requests handled.",
        "# TYPE inventrack_http_requests_total counter",
        "# HELP inventrack_http_request_duration_seconds_total Total HTTP duration in seconds.",
        "# TYPE inventrack_http_request_duration_seconds_total counter",
        "# HELP inventrack_http_p95_latency_seconds Latencia p95 en segundos asociada al escenario ESC-04.",
        "# TYPE inventrack_http_p95_latency_seconds gauge",
        "# HELP inventrack_messaging_messages_total Mensajes del broker por estado.",
        "# TYPE inventrack_messaging_messages_total counter",
    ]
    for status, value in sorted(_broker_mensajeria.metrics.items()):
        lines.append(f'inventrack_messaging_messages_total{{status="{status}"}} {value}')
    for method, path in sorted(_request_count):
        labels = f'method="{_prometheus_escape(method)}",path="{_prometheus_escape(path)}"'
        lines.append(f"inventrack_http_requests_total{{{labels}}} {_request_count[(method, path)]}")
        lines.append(f"inventrack_http_request_duration_seconds_total{{{labels}}} {_request_duration_seconds[(method, path)]}")
        
        # El historial nunca está vacío porque se itera sobre _request_count, evitando ramas condicionales
        history = list(_request_durations_history[(method, path)])
        lines.append(f"inventrack_http_p95_latency_seconds{{{labels}}} {round(_p95_latency(history), 4)}")
        
    return Response("\n".join(lines) + "\n", media_type="text/plain; version=0.0.4")


_seguridad = [Depends(HTTPBearer(auto_error=False, description="Token individual del perfil durable"))]
_errores_acceso = {401: {"description": "Credencial ausente o inválida"},
                   403: {"description": "Rol insuficiente"}, 503: {"description": "Service Unavailable"}}


def _guardar_evento_y_alerta(evento):
    guardar_evento(evento)
    registrar_cruce(conexion.get(), evento)


@app.get("/inventario/{producto_id}/movimientos", tags=["inventario"],
         dependencies=_seguridad, responses=_errores_acceso)
def historial(producto_id: str) -> list[Movimiento]:
    return list(reversed(_movimientos_repo.listar_por_producto(producto_id)))


app.include_router(router_usuarios, tags=["usuarios"], dependencies=_seguridad, responses=_errores_acceso)
app.include_router(crear_router_proveedores(bool(_db_path)), tags=["proveedores"],
                   dependencies=_seguridad, responses=_errores_acceso)
app.include_router(crear_router_cierres(_productos_repo, _stock_repo, bool(_db_path)), tags=["inventario"],
                   dependencies=_seguridad, responses=_errores_acceso)
app.include_router(
    crear_router_productos(_crear_producto, _eliminar_producto, _consultar_producto),
    tags=["productos"],
    dependencies=_seguridad, responses=_errores_acceso,
)
app.include_router(
    crear_router_inventario(
        _registrar_movimiento,
        _stock_repo,
        _broker_mensajeria,
        _consumir_auditoria_movimiento,
        _idempotency_store,
        _guardar_evento_y_alerta if _db_path else None,
    ),
    tags=["inventario"],
    dependencies=_seguridad, responses=_errores_acceso,
)
