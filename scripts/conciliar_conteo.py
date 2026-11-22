"""Comparar un conteo físico por SKU con una copia SQLite del cierre de turno."""

import argparse
import csv
import json
import sqlite3
from contextlib import closing
from pathlib import Path


if __package__ in (None, ""):
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.inventario.application.conciliacion import comparar, interpretar_csv


def leer_conteo(archivo):
    with archivo.open(encoding="utf-8-sig", newline="") as fuente:
        return interpretar_csv(fuente)


def conciliar(copia, conteo):
    with closing(sqlite3.connect(copia.resolve().as_uri() + "?mode=ro", uri=True)) as db:
        saldos = dict(db.execute("""
            SELECT p.id, COALESCE(s.cantidad, 0)
            FROM productos AS p LEFT JOIN stocks AS s ON p.id = s.producto_id
            WHERE p.activo = 1 OR s.cantidad > 0
        """))
    return comparar(saldos, conteo)


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("copia", type=Path, help="Instantánea SQLite tomada al cierre")
    cli.add_argument("conteo", type=Path, help="Archivo CSV UTF-8 con columnas sku,cantidad")
    args = cli.parse_args()
    try:
        informe = conciliar(args.copia, leer_conteo(args.conteo))
    except (OSError, ValueError, csv.Error, sqlite3.Error) as exc:
        cli.exit(2, f"Error al conciliar: {exc}\n")
    print(json.dumps(informe, ensure_ascii=False, indent=2))
    return 1 if informe["diferencias"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
