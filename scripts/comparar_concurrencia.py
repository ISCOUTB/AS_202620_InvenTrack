"""Repite el reto ADR-0002 en dos revisiones Git sin modificar el checkout."""

import argparse
import asyncio
import hashlib
import io
import json
import math
import os
import platform
import shutil
import sqlite3
import statistics
import subprocess
import sys
import tempfile
import time
import zipfile
from contextlib import closing
from importlib.metadata import version
from pathlib import Path


S10 = "539840be57f8a0b719bb33e19d05031489a25b86"


async def medir(directorio, perfil):
    import httpx

    sys.path.insert(0, str(directorio))
    cabeceras = {}
    if perfil == "sqlite":
        from app.shared.infrastructure.sqlite import inicializar
        from app.usuarios.infrastructure.credenciales import emitir

        ruta = Path.cwd() / "ensayo.sqlite3"
        os.environ.update(INVENTRACK_DB_PATH=str(ruta), INVENTRACK_ENV="production",
                          INVENTRACK_ALLOW_BUSINESS_DATA="true")
        inicializar(ruta)
        with closing(sqlite3.connect(ruta)) as db, db:
            cabeceras["Authorization"] = "Bearer " + emitir(db, "ensayo", "admin")

    from app.main import app

    async with app.router.lifespan_context(app), httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test", headers=cabeceras
    ) as cliente:
        sku = "ARROZ-1KG"
        ruta = f"/inventario/{sku}"
        alta = await cliente.post("/productos", json={"id": sku, "nombre": "Arroz de un kilo"})
        assert alta.status_code == 201
        carga = await cliente.post(f"{ruta}/entradas", json={"cantidad": 100})
        assert carga.status_code == 200

        async def salida(i):
            inicio = time.perf_counter()
            respuesta = await cliente.post(f"{ruta}/salidas", json={"cantidad": 1},
                                          headers={"X-Idempotency-Key": f"venta-{i}"})
            ms = (time.perf_counter() - inicio) * 1000
            return {"ms": round(ms, 3), "http": respuesta.status_code,
                    "saldo": respuesta.json().get("stock_final")}

        muestras = await asyncio.gather(*(salida(i) for i in range(20)))
        consulta = await cliente.get(ruta)
        assert consulta.status_code == 200
        assert all(m["http"] == 200 for m in muestras)
        assert sorted(m["saldo"] for m in muestras) == list(range(80, 100))
        saldo = consulta.json()["cantidad"]
        assert saldo == 80
        rango = math.ceil(len(muestras) * 0.95)
        return {"salidas": muestras, "saldo_final": saldo,
                "p95_ms": sorted(m["ms"] for m in muestras)[rango - 1]}


def comparar(actual):
    casos = {}
    entorno = {k: v for k, v in os.environ.items() if not k.startswith("INVENTRACK_")}
    with tempfile.TemporaryDirectory() as temporal:
        raiz = Path(temporal)
        for etiqueta, ref, perfil in [("S10", S10, "memoria"), ("S16", actual, "memoria"),
                                      ("S16_durable", actual, "sqlite")]:
            fuente = raiz / etiqueta
            if ref == "trabajo":
                shutil.copytree("app", fuente / "app", ignore=shutil.ignore_patterns("__pycache__"))
                huella = hashlib.sha256()
                for ruta in sorted(fuente.rglob("*.py")):
                    huella.update(ruta.relative_to(fuente).as_posix().encode() + b"\0")
                    huella.update(ruta.read_text(encoding="utf-8").encode() + b"\0")
                revision = "app-sha256:" + huella.hexdigest()
            else:
                revision = subprocess.check_output(["git", "rev-parse", "--verify", ref + "^{commit}"],
                                                   text=True).strip()
                datos = subprocess.check_output(["git", "archive", "--format=zip", revision, "app"])
                with zipfile.ZipFile(io.BytesIO(datos)) as archivo:
                    archivo.extractall(fuente)
            casos[etiqueta] = {"revision": revision, "perfil": perfil, "corridas": []}
        for ronda in range(3):
            # Rotar el orden para repartir el efecto de calentamiento de la máquina.
            orden = list(casos)
            for etiqueta in orden[ronda:] + orden[:ronda]:
                caso = casos[etiqueta]
                with tempfile.TemporaryDirectory(dir=raiz) as trabajo:
                    proceso = subprocess.run(
                        [sys.executable, "-I", str(Path(__file__).resolve()), "--medir",
                         str(raiz / etiqueta), caso["perfil"]], cwd=trabajo, env=entorno,
                        stdout=subprocess.PIPE, text=True, check=True)
                    caso["corridas"].append(json.loads(proceso.stdout))
    for caso in casos.values():
        caso["mediana_p95_ms"] = statistics.median(c["p95_ms"] for c in caso["corridas"])
    return {"transporte": "ASGI en proceso", "plataforma": platform.system(),
            "python": platform.python_version(), "fastapi": version("fastapi"),
            "httpx": version("httpx"), "umbral_ms": 400, "casos": casos}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--actual", default="HEAD")
    parser.add_argument("--salida", type=Path)
    parser.add_argument("--medir", nargs=2, help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.medir:
        print(json.dumps(asyncio.run(medir(*args.medir))))
    else:
        informe = comparar(args.actual)
        contenido = json.dumps(informe, indent=2) + "\n"
        if args.salida:
            args.salida.write_text(contenido, encoding="utf-8")
        else:
            print(contenido)
        if any(c["p95_ms"] > informe["umbral_ms"] for caso in informe["casos"].values()
               for c in caso["corridas"]):
            sys.exit("Al menos una corrida superó el umbral de 400 ms")
