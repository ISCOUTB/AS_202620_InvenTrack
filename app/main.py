"""Punto de entrada de InvenTrack.

Este esqueleto solo ensambla FastAPI y expone un endpoint de salud.
La logica de negocio se implementara dentro de los modulos funcionales.
"""

from fastapi import FastAPI

app = FastAPI(
    title="InvenTrack",
    description="Sistema de gestion de inventarios para pequenas empresas.",
    version="0.1.0",
)


@app.get("/health", tags=["infraestructura"])
def health_check() -> dict[str, str]:
    return {"status": "ok", "service": "InvenTrack"}
