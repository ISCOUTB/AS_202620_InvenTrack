"""Punto de entrada de InvenTrack.

Este archivo ensambla la aplicación y registra los routers de cada módulo.
La lógica de negocio vive dentro de los módulos funcionales, siguiendo la
arquitectura hexagonal adoptada en el ADR-0001.
"""

from fastapi import FastAPI

from app.inventario.infrastructure.router import router as inventario_router
from app.productos.infrastructure.router import router as productos_router

app = FastAPI(
    title="InvenTrack",
    description="Sistema de gestión de inventarios para pequeñas empresas.",
    version="0.1.0",
)


@app.get("/health", tags=["infraestructura"])
def health_check() -> dict[str, str]:
    return {"status": "ok", "service": "InvenTrack"}


app.include_router(productos_router, tags=["productos"])
app.include_router(inventario_router, tags=["inventario"])
