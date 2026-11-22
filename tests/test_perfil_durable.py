import json
import os
import sqlite3
import subprocess
import sys
from contextlib import closing
from pathlib import Path

import pytest
from httpx import ASGITransport, AsyncClient

from app.shared.infrastructure.respaldo import copiar
from app.shared.infrastructure.sqlite import inicializar
from app.usuarios.infrastructure.credenciales import emitir


@pytest.mark.asyncio
async def test_escritor_ocupado_permite_lectura_y_libera_turno(tmp_path, monkeypatch):
    from app import main
    from app.shared.infrastructure import sqlite

    ruta = tmp_path / "contencion.sqlite3"
    inicializar(ruta)
    with closing(sqlite3.connect(ruta)) as db, db:
        token = emitir(db, "ensayo", "admin")
    monkeypatch.setattr(main, "_db_path", str(ruta))
    monkeypatch.setenv("INVENTRACK_ALLOW_BUSINESS_DATA", "true")
    monkeypatch.setattr(sqlite, "_ESPERA_SEGUNDOS", 0.2)
    async with AsyncClient(transport=ASGITransport(app=main.app), base_url="http://test",
                           headers={"Authorization": f"Bearer {token}"}) as cliente:
        # Un SKU inválido evita modificar el catálogo del proceso de prueba.
        ruta_salida = "/inventario/sku-ausente-contencion/salidas"
        async with sqlite.transaccion(ruta, escritura=True):
            assert (await cliente.get("/productos")).status_code == 200
            ocupada = await cliente.post(ruta_salida, json={"cantidad": 1})
            assert ocupada.status_code == 503
            assert ocupada.headers["retry-after"] == "1"
        assert (await cliente.post(ruta_salida, json={"cantidad": 1})).status_code == 404


def test_respaldo_restringe_rutas_y_preserva_destino(tmp_path, monkeypatch):
    ruta = tmp_path / "original.sqlite3"
    monkeypatch.setenv("INVENTRACK_DB_PATH", str(ruta))
    inicializar(ruta)
    for invalida in (Path("../otra.sqlite3"), tmp_path.parent / "otra.sqlite3", Path("file:copia?mode=rw")):
        with pytest.raises(ValueError):
            copiar(ruta, invalida)
        with pytest.raises(ValueError):
            copiar(invalida, Path("copia.sqlite3"))
    destino = tmp_path / "existente.sqlite3"
    destino.write_bytes(b"conservar")
    with pytest.raises(FileExistsError):
        copiar(ruta, destino)
    assert destino.read_bytes() == b"conservar"


def test_recuperacion_y_permisos(tmp_path, monkeypatch):
    ruta = tmp_path / "original.sqlite3"
    monkeypatch.setenv("INVENTRACK_DB_PATH", str(ruta))
    inicializar(ruta)
    with closing(sqlite3.connect(ruta)) as db, db:
        tokens = {rol: emitir(db, rol, rol) for rol in ("lector", "operador", "admin")}
    entorno = dict(os.environ, INVENTRACK_ENV="production", INVENTRACK_ALLOW_BUSINESS_DATA="true",
                   INVENTRACK_DB_PATH=str(ruta), TEST_TOKENS=json.dumps(tokens))
    comando = [sys.executable, "-m", "tests.test_perfil_durable"]
    subprocess.run([*comando, "alta"], env=entorno, check=True)
    copia = tmp_path / "copia.sqlite3"
    restaurada = tmp_path / "restaurada.sqlite3"
    copiar(ruta, copia)
    copiar(copia, restaurada)
    entorno["INVENTRACK_DB_PATH"] = str(restaurada)
    subprocess.run([*comando, "reinicio"], env=entorno, check=True)
    with closing(sqlite3.connect(restaurada)) as db:
        evento, = db.execute("SELECT evento FROM auditoria").fetchone()
        assert json.loads(evento)["actor_id"] == "operador"
        assert db.execute("SELECT actor_id,cantidad FROM movimientos").fetchall() == [("operador", 7)]
        assert db.execute("SELECT count(*) FROM auditoria").fetchone()[0] == 1


def comprobar_perfil(fase):
    from fastapi.testclient import TestClient
    from app.main import app

    tokens = json.loads(os.environ["TEST_TOKENS"])
    headers = {rol: {"Authorization": f"Bearer {valor}"} for rol, valor in tokens.items()}
    comando = dict(headers={**headers["operador"], "X-Idempotency-Key": "entrada-1"}, json={"cantidad": 7})
    with TestClient(app) as client:
        if fase == "alta":
            assert client.get("/productos").status_code == 401
            assert client.get("/productos", headers={"Authorization": "Bearer invalido"}).status_code == 401
            producto = {"id": "prueba", "nombre": "Prueba"}
            assert client.post("/productos", headers=headers["operador"], json=producto).status_code == 403
            assert client.post("/productos", headers=headers["admin"], json=producto).status_code == 201
            assert client.post("/productos", headers=headers["admin"], json=producto).status_code == 409
            assert client.post("/inventario/prueba/entradas", headers=headers["lector"], json={"cantidad": 1}).status_code == 403
            assert client.post("/inventario/prueba/entradas", headers=headers["operador"],
                               json={"cantidad": 2**63}).status_code == 400
            with closing(sqlite3.connect(os.environ["INVENTRACK_DB_PATH"])) as db, db:
                db.execute("""CREATE TRIGGER simular_fallo BEFORE INSERT ON auditoria
                              BEGIN SELECT RAISE(ABORT, 'fallo simulado'); END""")
            with TestClient(app, raise_server_exceptions=False) as cliente_con_fallo:
                assert cliente_con_fallo.post("/inventario/prueba/entradas", **comando).status_code == 500
            assert client.get("/inventario/prueba", headers=headers["lector"]).status_code == 404
            with closing(sqlite3.connect(os.environ["INVENTRACK_DB_PATH"])) as db, db:
                assert db.execute("SELECT count(*) FROM comandos").fetchone()[0] == 0
                db.execute("DROP TRIGGER simular_fallo")
        respuesta = client.post("/inventario/prueba/entradas", **comando)
        assert respuesta.status_code == 200
        assert respuesta.json()["stock_final"] == 7
        assert client.get("/inventario/prueba", headers=headers["lector"]).json()["cantidad"] == 7
        if fase == "reinicio":
            assert client.delete("/productos/prueba", headers=headers["admin"]).json()["desactivado"]
            with closing(sqlite3.connect(os.environ["INVENTRACK_DB_PATH"])) as db, db:
                emitir(db, "lector", "lector")
            assert client.get("/productos", headers=headers["lector"]).status_code == 401


if __name__ == "__main__":
    comprobar_perfil(sys.argv[1])
