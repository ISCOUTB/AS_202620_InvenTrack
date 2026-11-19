"""ESC-01 y ESC-04 sobre ASGI o sobre una instancia de ensayo dedicada."""

import asyncio
import json
import math
import os
import platform
import time
from pathlib import Path
from uuid import uuid4

import httpx
import pytest

from app.main import app


@pytest.mark.asyncio
async def test_escenarios_arc42():
    destino = os.getenv("INVENTRACK_ENSAYO_URL")
    transporte = None if destino else httpx.ASGITransport(app=app)
    informe = {"entorno": destino or "ASGI en proceso", "python": platform.python_version(),
               "plataforma": platform.system(), "corridas": []}
    token = os.getenv("INVENTRACK_ENSAYO_TOKEN") if destino else None
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient(transport=transporte, headers=headers, base_url=destino or "http://test",
                                 trust_env=False, timeout=10) as cliente:
        for _ in range(3):
            sku = f"ensayo-{uuid4().hex}"
            ruta = f"/inventario/{sku}"
            creado = await cliente.post("/productos", json={"id": sku, "nombre": "Ensayo de carga"})
            assert creado.status_code == 201
            entrada = await cliente.post(f"{ruta}/entradas", json={"cantidad": 40})
            assert entrada.status_code == 200

            async def salida(indice):
                return await cliente.post(f"{ruta}/salidas", json={"cantidad": 1},
                                          headers={"X-Idempotency-Key": f"{sku}-{indice}"})

            respuestas = await asyncio.gather(*(salida(i) for i in range(50)))
            saldos = [r.json()["stock_final"] for r in respuestas if r.status_code == 200]
            assert sorted(saldos) == list(range(40))
            assert sum(r.status_code == 409 for r in respuestas) == 10
            indice = next(i for i, r in enumerate(respuestas) if r.status_code == 200)
            repetida = await salida(indice)
            assert repetida.status_code == 200
            assert repetida.json() == respuestas[indice].json()
            assert (await cliente.get(ruta)).json()["cantidad"] == 0

            inicio = time.perf_counter()

            async def consulta(i):
                await asyncio.sleep(max(0, inicio + i / 20 - time.perf_counter()))
                salida_en = time.perf_counter()
                r = await cliente.get(ruta)
                duracion = time.perf_counter() - salida_en
                assert r.status_code == 200 and r.json()["cantidad"] == 0
                return {"inicio_ms": round((salida_en - inicio) * 1000, 3),
                        "latencia_ms": duracion * 1000, "http": r.status_code}

            muestras = await asyncio.gather(*(consulta(i) for i in range(40)))
            latencias = sorted(m["latencia_ms"] for m in muestras)
            p95 = latencias[math.ceil(len(latencias) * 0.95) - 1]
            informe["corridas"].append({"sku": sku, "salidas_http": [r.status_code for r in respuestas],
                                        "saldos_confirmados": saldos, "saldo_final": 0,
                                        "consultas": muestras, "p95_ms": p95})

    archivo = os.getenv("INVENTRACK_ENSAYO_JSON")
    if archivo:
        Path(archivo).write_text(json.dumps(informe, indent=2) + "\n", encoding="utf-8")
    assert all(c["p95_ms"] <= 400 for c in informe["corridas"])
