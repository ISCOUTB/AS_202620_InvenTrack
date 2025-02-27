import json
from pathlib import Path

from app.main import app


CONTRACT_PATH = Path(__file__).parents[2] / "contracts" / "openapi" / "v1.json"


def test_api_implementa_contrato_openapi_v1() -> None:
    contrato = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    implementacion = app.openapi()

    assert contrato["openapi"] == implementacion["openapi"]
    assert contrato["info"] == implementacion["info"]
    assert set(contrato["paths"]) == set(implementacion["paths"])

    for ruta, operaciones in contrato["paths"].items():
        assert set(operaciones) == set(implementacion["paths"][ruta])
        for metodo, contrato_operacion in operaciones.items():
            implementacion_operacion = implementacion["paths"][ruta][metodo]
            assert contrato_operacion["responses"] == implementacion_operacion["responses"]

            assert contrato_operacion.get("parameters") == implementacion_operacion.get("parameters")
            assert contrato_operacion.get("requestBody") == implementacion_operacion.get("requestBody")

    assert contrato["components"]["schemas"] == implementacion["components"]["schemas"]