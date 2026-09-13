"""Punto de entrada de InvenTrack.

Este archivo es el composition root de la aplicación: construye los
repositorios, casos de uso y adaptadores de cada módulo, resuelve las
dependencias cruzadas entre módulos (ADR-0003) y ensambla los routers.
Los routers ya no construyen sus propias dependencias (consecuencia del
hallazgo "wiring hardcodeado en el router").
"""

from fastapi import FastAPI

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


@app.get("/health", tags=["infraestructura"])
def health_check() -> dict[str, str]:
    return {"status": "ok", "service": "InvenTrack"}


app.include_router(
    crear_router_productos(_crear_producto, _eliminar_producto), tags=["productos"]
)
app.include_router(
    crear_router_inventario(_registrar_movimiento, _stock_repo), tags=["inventario"]
)
