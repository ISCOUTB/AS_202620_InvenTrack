# Evidencia: la prueba de contrato detecta cambios incompatibles

Este documento respalda la afirmación hecha en la sección "Evidencia" del
[ADR-0004](adr/0004-contrato-api-versionado-openapi.md): que
`tests/contract/test_openapi_contract.py` no es una prueba decorativa —
falla de verdad cuando la implementación deja de cumplir el contrato
publicado en `contracts/openapi/v1.json`.

- **Commit verificado:** `9a5c17db1e3fc78e1a55e2739fdb39fc21a3de64` (2026-09-22T18:49:46-05:00)
- **Comando de referencia:** `PYTHONPATH=. pytest tests/contract/test_openapi_contract.py -v`
- **Método:** se retiró manualmente el código `503` de las respuestas
  documentadas del endpoint `POST /inventario/{producto_id}/entradas` en
  `app/inventario/infrastructure/router.py`, sin tocar el contrato ni la
  lógica que sí lanza ese `503` — exactamente el tipo de cambio incompatible
  que la prueba existe para detectar (alguien documenta menos de lo que el
  contrato promete). Después se revirtió el archivo a su estado original.

## Paso 1 — Estado base: la prueba pasa

```
tests/contract/test_openapi_contract.py::test_api_implementa_contrato_openapi_v1 PASSED [100%]
============================== 1 passed in 0.26s ===============================
```

## Paso 2 — Cambio incompatible aplicado

```diff
--- a/app/inventario/infrastructure/router.py
+++ b/app/inventario/infrastructure/router.py
@@ -24,7 +24,7 @@

     @router.post(
         "/inventario/{producto_id}/entradas",
-        responses={404: {"description": "Not Found"}, 503: {"description": "Service Unavailable"}},
+        responses={404: {"description": "Not Found"}},
     )
     async def registrar_entrada(producto_id: str, payload: MovimientoRequest) -> MovimientoResponse:
         try:
```

## Paso 3 — La prueba falla

```
tests/contract/test_openapi_contract.py::test_api_implementa_contrato_openapi_v1 FAILED [100%]

=================================== FAILURES ===================================
___________________ test_api_implementa_contrato_openapi_v1 ____________________

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
>               assert contrato_operacion["responses"] == implementacion_operacion["responses"]
E               AssertionError: assert {'200': {'con...Unavailable'}} == {'200': {'con...ation Error'}}
E
E                 Omitting 3 identical items, use -vv to show
E                 Left contains 1 more item:
E                 {'503': {'description': 'Service Unavailable'}}
E
E                 Full diff:
E                   {...
E
E                 ...Full output truncated (27 lines hidden), use '-vv' to show

tests/contract/test_openapi_contract.py:22: AssertionError
=========================== short test summary info ============================
FAILED tests/contract/test_openapi_contract.py::test_api_implementa_contrato_openapi_v1
============================== 1 failed in 0.24s ===============================
```

El mensaje señala exactamente el `503` que el contrato promete (`Left contains
1 more item: {'503': ...}`) y que la implementación modificada dejó de
documentar.

## Paso 4 — Revertido: la prueba vuelve a pasar

```
tests/contract/test_openapi_contract.py::test_api_implementa_contrato_openapi_v1 PASSED [100%]
============================== 1 passed in 0.23s ===============================
```

`git status` tras revertir no mostró ningún cambio pendiente — el repositorio
quedó exactamente como estaba antes de esta verificación.

## Cómo reproducirlo

```bash
git checkout 9a5c17db1e3fc78e1a55e2739fdb39fc21a3de64
pip install --require-hashes --only-binary :all: -r requirements.txt
PYTHONPATH=. pytest tests/contract/test_openapi_contract.py -v   # PASA

# Editar app/inventario/infrastructure/router.py: quitar el 503 de
# `responses=` en POST /inventario/{producto_id}/entradas

PYTHONPATH=. pytest tests/contract/test_openapi_contract.py -v   # FALLA

git checkout -- app/inventario/infrastructure/router.py
PYTHONPATH=. pytest tests/contract/test_openapi_contract.py -v   # PASA de nuevo
```
