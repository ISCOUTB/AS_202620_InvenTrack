import json
import sqlite3
import subprocess
import sys
from contextlib import closing

import pytest

from app.shared.infrastructure.respaldo import copiar
from app.shared.infrastructure.sqlite import inicializar
from scripts.conciliar_conteo import leer_conteo


def test_conciliar_sobre_la_copia_del_turno(tmp_path, monkeypatch):
    original = tmp_path / "operacion.sqlite3"
    copia = tmp_path / "cierre.sqlite3"
    monkeypatch.setenv("INVENTRACK_DB_PATH", str(original))
    inicializar(original)
    with closing(sqlite3.connect(original)) as db, db:
        db.executemany("INSERT INTO productos VALUES(?,?,?)", [
            ("ARROZ", "Arroz", 1), ("CAFE", "Café", 1), ("SAL", "Sal", 1),
            ("TE", "Té desactivado con saldo", 0), ("JUGO", "Jugo retirado", 0)])
        db.executemany("INSERT INTO stocks VALUES(?,?)", [("ARROZ", 20), ("CAFE", 10), ("TE", 5)])
    copiar(original, copia)
    with closing(sqlite3.connect(original)) as db, db:
        db.execute("UPDATE stocks SET cantidad=19 WHERE producto_id='ARROZ'")

    archivo = tmp_path / "conteo.csv"
    comando = [sys.executable, "-m", "scripts.conciliar_conteo", str(copia), str(archivo)]
    archivo.write_text("sku,cantidad\nARROZ,18\nCAFE,12\nTE,5\nOTRO,0\n", encoding="utf-8")
    datos_antes = copia.read_bytes()
    resultado = subprocess.run(comando, capture_output=True, text=True)
    assert resultado.returncode == 1, resultado.stderr
    informe = json.loads(resultado.stdout)
    assert informe["total_esperado"] == informe["total_contado"] == 35
    assert informe["diferencias"] == [
        {"sku": "ARROZ", "motivo": "diferencia_de_unidades", "esperado": 20, "contado": 18, "diferencia": -2},
        {"sku": "CAFE", "motivo": "diferencia_de_unidades", "esperado": 10, "contado": 12, "diferencia": 2},
        {"sku": "OTRO", "motivo": "fuera_del_corte", "esperado": None, "contado": 0, "diferencia": None},
        {"sku": "SAL", "motivo": "sin_conteo", "esperado": 0, "contado": None, "diferencia": None},
    ]
    archivo.write_text("sku,cantidad\nARROZ,20\nCAFE,10\nSAL,0\nTE,5\n", encoding="utf-8")
    correcto = subprocess.run(comando, capture_output=True, text=True, check=True)
    assert json.loads(correcto.stdout)["diferencias"] == []
    assert copia.read_bytes() == datos_antes


@pytest.mark.parametrize("filas", ["A,2\nA,2", "A,-1", "A,1.5", "A,", ",2", "A,2,3"])
def test_rechazar_conteo_invalido(tmp_path, filas):
    archivo = tmp_path / "conteo.csv"
    archivo.write_text("sku,cantidad\n" + filas, encoding="utf-8")
    with pytest.raises(ValueError):
        leer_conteo(archivo)
