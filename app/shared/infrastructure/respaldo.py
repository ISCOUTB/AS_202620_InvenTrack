"""Copiar una base consistente a un archivo nuevo para respaldo o restauración."""
import argparse
import sqlite3
from contextlib import closing
from pathlib import Path


def copiar(origen: Path, destino: Path):
    with closing(sqlite3.connect(origen.resolve().as_uri() + "?mode=ro", uri=True)) as fuente:
        destino.touch(mode=0o600, exist_ok=False)
        try:
            with closing(sqlite3.connect(destino)) as copia:
                fuente.backup(copia)
                if copia.execute("PRAGMA integrity_check").fetchall() != [("ok",)]:
                    raise ValueError("Falló la verificación de integridad de la copia")
        except BaseException:
            destino.unlink()
            raise


if __name__ == "__main__":
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("origen", type=Path)
    cli.add_argument("destino", type=Path)
    argumentos = cli.parse_args()
    copiar(argumentos.origen, argumentos.destino)
