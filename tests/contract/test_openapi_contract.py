import json
from pathlib import Path

from app.main import app


CONTRACT_PATH = Path(__file__).parents[2] / "contracts" / "openapi" / "v1.json"


def test_api_implementa_contrato_openapi_v1() -> None:
    contrato = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    implementacion = app.openapi()

    assert contrato["openapi"] == implementacion["openapi"]
    assert contrato["info"] == implementacion["info"]

    for ruta, operaciones in contrato["paths"].items():
        assert ruta in implementacion["paths"]
        for metodo, contrato_operacion in operaciones.items():
            implementacion_operacion = implementacion["paths"][ruta][metodo]
            assert set(contrato_operacion["responses"]) <= set(
                implementacion_operacion["responses"]
            )

            if "parameters" in contrato_operacion:
                assert contrato_operacion["parameters"] == implementacion_operacion["parameters"]
            if "requestBody" in contrato_operacion:
                assert contrato_operacion["requestBody"] == implementacion_operacion["requestBody"]

    for nombre, esquema in contrato["components"]["schemas"].items():
        assert implementacion["components"]["schemas"][nombre] == esquema