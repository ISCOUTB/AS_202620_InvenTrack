import csv
import json
from datetime import datetime, timezone
from io import StringIO
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.inventario.application.conciliacion import comparar, interpretar_csv
from app.shared.infrastructure.sqlite import conexion


class Conteo(BaseModel):
    csv: str = Field(min_length=1, max_length=1_000_000)


class Cierre(BaseModel):
    id: str
    fecha: str


class Diferencia(BaseModel):
    sku: str
    motivo: str
    esperado: int | None
    contado: int | None
    diferencia: int | None


class Informe(BaseModel):
    total_esperado: int
    total_contado: int
    diferencias: list[Diferencia]


def _leer_saldos(id: str, durable: bool, memoria) -> dict[str, int] | None:
    if durable:
        fila = conexion.get().execute("SELECT saldos FROM cierres WHERE id=?", (id,)).fetchone()
        return json.loads(fila[0]) if fila else None
    return memoria[id][1] if id in memoria else None


def crear_router(productos, stocks, durable: bool):
    router = APIRouter(prefix="/cierres")
    memoria: dict[str, tuple[Cierre, dict[str, int]]] = {}

    @router.post("", status_code=201)
    async def crear() -> Cierre:
        cierre = Cierre(id=str(uuid4()), fecha=datetime.now(timezone.utc).isoformat())
        cantidades = {s.producto_id: s.cantidad for s in stocks.listar()}
        saldos = {p.id: cantidades.get(p.id, 0) for p in productos.listar()
                  if p.activo or cantidades.get(p.id, 0) > 0}
        if durable:
            conexion.get().execute("INSERT INTO cierres(id,fecha,saldos) VALUES(?,?,?)",
                                   (cierre.id, cierre.fecha, json.dumps(saldos)))
        else:
            memoria[cierre.id] = (cierre, saldos)
        return cierre

    @router.get("")
    async def listar() -> list[Cierre]:
        if durable:
            filas = conexion.get().execute("SELECT id,fecha FROM cierres ORDER BY fecha DESC")
            return [Cierre(id=i, fecha=f) for i, f in filas]
        return [c for c, _ in reversed(memoria.values())]

    @router.post("/{id}/conciliar", responses={
        404: {"description": "Cierre inexistente"},
        422: {"description": "Solicitud inválida o CSV de conteo inválido"},
    })
    async def conciliar_cierre(id: str, conteo: Conteo) -> Informe:
        saldos = _leer_saldos(id, durable, memoria)
        if saldos is None:
            raise HTTPException(404, "Cierre inexistente")
        try:
            cantidades = interpretar_csv(StringIO(conteo.csv, newline=""))
        except (ValueError, csv.Error) as exc:
            raise HTTPException(422, str(exc)) from exc
        return Informe(**comparar(saldos, cantidades))

    return router
