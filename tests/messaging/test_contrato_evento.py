import json
from datetime import datetime
from pathlib import Path
from uuid import UUID

from app.inventario.infrastructure.router import MovimientoResponse, _crear_evento


CONTRACT_PATH = Path("contracts/events/movimiento_registrado_v1.json")


def test_evento_generado_cumple_contrato_v1():
    contrato = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    evento = _crear_evento(
        MovimientoResponse(
            producto_id="SKU-001",
            cantidad=2,
            tipo="entrada",
            stock_final=8,
        ),
        "corr-contract-001",
        "cmd-001",
    )

    assert set(evento) == set(contrato["required"])
    UUID(evento["event_id"])
    datetime.fromisoformat(evento["timestamp"].replace("Z", "+00:00"))
    assert evento["correlation_id"] == "corr-contract-001"
    assert evento["idempotency_key"] == "cmd-001"
    assert evento["data"]["tipo"] == "ENTRADA"
    assert set(evento["data"]) == set(contrato["properties"]["data"]["required"])
    assert evento["data"]["tipo"] in contrato["properties"]["data"]["properties"]["tipo"]["enum"]