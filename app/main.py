"""Punto de entrada de InvenTrack.

Este archivo es el composition root de la aplicación: construye los
repositorios, casos de uso y adaptadores de cada módulo, resuelve las
dependencias cruzadas entre módulos (ADR-0003) y ensambla los routers.
Los routers ya no construyen sus propias dependencias (consecuencia del
hallazgo "wiring hardcodeado en el router").
"""

import json
import logging
import time
from collections import defaultdict
from collections.abc import Awaitable, Callable
from typing import Any

from fastapi import FastAPI, Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

from app.inventario.application.consultar_movimientos import ConsultarHistorialMovimientos
from app.inventario.application.registrar_movimiento import RegistrarMovimientoInventario
from app.inventario.infrastructure.in_memory_movimiento_repository import (
    InMemoryMovimientoRepository,
)
from app.inventario.infrastructure.in_memory_repository import InMemoryStockRepository
from app.inventario.infrastructure.router import crear_router as crear_router_inventario
from app.inventario.infrastructure.validador_producto_adapter import ValidadorDeProductoAdapter
from app.productos.application.consultar_producto import ConsultarProducto
from app.productos.application.crear_producto import CrearProducto
from app.productos.application.eliminar_producto import EliminarProducto
from app.productos.infrastructure.historial_movimientos_adapter import (
    HistorialMovimientosAdapter,
)
from app.productos.infrastructure.in_memory_repository import InMemoryProductoRepository
from app.productos.infrastructure.router import crear_router as crear_router_productos


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

_request_count: defaultdict[tuple[str, str], int] = defaultdict(int)
_request_duration_seconds: defaultdict[tuple[str, str], float] = defaultdict(float)


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

# --- productos: repositorio y casos de uso propios ---
_productos_repo = InMemoryProductoRepository()
_consultar_producto = ConsultarProducto(_productos_repo)
_crear_producto = CrearProducto(_productos_repo)

# --- inventario: repositorios y casos de uso propios ---
_stock_repo = InMemoryStockRepository()
_movimientos_repo = InMemoryMovimientoRepository()
_consultar_historial = ConsultarHistorialMovimientos(_movimientos_repo)

# --- adaptadores cruzados (ADR-0003): cada uno solo importa la
#     `application` del módulo contrario, nunca su domain/infrastructure ---
_validador_producto = ValidadorDeProductoAdapter(_consultar_producto)
_historial_movimientos = HistorialMovimientosAdapter(_consultar_historial)

# --- casos de uso que dependen de un adaptador cruzado ---
_eliminar_producto = EliminarProducto(_productos_repo, _historial_movimientos)
# RegistrarMovimientoInventario serializa por producto_id con un
# asyncio.Lock interno (ADR-0002, equipo — control de concurrencia).
_registrar_movimiento = RegistrarMovimientoInventario(
    _stock_repo, _movimientos_repo, _validador_producto
)

app = FastAPI(
    title="InvenTrack",
    description="Sistema de gestión de inventarios para pequeñas empresas.",
    version="0.1.0",
)
app.add_middleware(ObservabilityMiddleware)


@app.get("/health", tags=["infraestructura"])
def health_check() -> dict[str, str]:
    return {"status": "ok", "service": "InvenTrack"}


@app.get("/metrics", include_in_schema=False, tags=["infraestructura"])
def metrics() -> Response:
    lines = [
        "# HELP inventrack_http_requests_total Total HTTP requests handled.",
        "# TYPE inventrack_http_requests_total counter",
        "# HELP inventrack_http_request_duration_seconds_total Total HTTP duration in seconds.",
        "# TYPE inventrack_http_request_duration_seconds_total counter",
    ]
    for method, path in sorted(_request_count):
        labels = f'method="{_prometheus_escape(method)}",path="{_prometheus_escape(path)}"'
        lines.append(
            f"inventrack_http_requests_total{{{labels}}} {_request_count[(method, path)]}"
        )
        lines.append(
            "inventrack_http_request_duration_seconds_total"
            f"{{{labels}}} {_request_duration_seconds[(method, path)]}"
        )
    return Response("\n".join(lines) + "\n", media_type="text/plain; version=0.0.4")


app.include_router(
    crear_router_productos(_crear_producto, _eliminar_producto), tags=["productos"]
)
app.include_router(
    crear_router_inventario(_registrar_movimiento, _stock_repo), tags=["inventario"]
)
