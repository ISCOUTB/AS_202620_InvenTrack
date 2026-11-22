"""Comparar un conteo físico por SKU con una copia SQLite del cierre de turno."""

import argparse
import csv
import json
import sqlite3
from contextlib import closing
from pathlib import Path


def leer_conteo(archivo):
    cantidades = {}
    with archivo.open(encoding="utf-8-sig", newline="") as fuente:
        lector = csv.reader(fuente, strict=True)
        if next(lector, None) != ["sku", "cantidad"]:
            raise ValueError("Se esperaba la cabecera sku,cantidad")
        for fila in lector:
            if len(fila) != 2:
                raise ValueError(f"Fila {lector.line_num}: se esperaban dos columnas")
            sku, cantidad = fila
            if not sku.strip() or not cantidad.isascii() or not cantidad.isdecimal():
                raise ValueError(f"Fila {lector.line_num}: se requiere SKU y cantidad entera no negativa")
            if sku in cantidades:
                raise ValueError(f"Fila {lector.line_num}: SKU duplicado: {sku}")
            cantidades[sku] = int(cantidad)
    return cantidades


def conciliar(copia, conteo):
    with closing(sqlite3.connect(copia.resolve().as_uri() + "?mode=ro", uri=True)) as db:
        saldos = dict(db.execute("""
            SELECT p.id, COALESCE(s.cantidad, 0)
            FROM productos AS p LEFT JOIN stocks AS s ON p.id = s.producto_id
            WHERE p.activo = 1 OR s.cantidad > 0
        """))
    diferencias = []
    for sku in sorted(saldos.keys() | conteo.keys()):
        esperado = saldos.get(sku)
        contado = conteo.get(sku)
        if esperado == contado:
            continue
        diferencia = None
        if contado is None:
            motivo = "sin_conteo"
        elif esperado is None:
            motivo = "fuera_del_corte"
        else:
            motivo = "diferencia_de_unidades"
            diferencia = contado - esperado
        diferencias.append({"sku": sku, "motivo": motivo, "esperado": esperado,
                            "contado": contado, "diferencia": diferencia})
    return {"total_esperado": sum(saldos.values()), "total_contado": sum(conteo.values()),
            "diferencias": diferencias}


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
