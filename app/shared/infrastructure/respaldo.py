"""Copiar una base consistente a un archivo nuevo para respaldo o restauración."""
import argparse
import os
import re
import sqlite3
from contextlib import closing
from pathlib import Path, PureWindowsPath
from tempfile import TemporaryDirectory


def _archivo_local(ruta: Path, directorio: Path) -> Path:
    if ruta.parent not in (Path("."), directorio):
        raise ValueError("El archivo debe estar en el directorio de datos configurado")
    if not re.fullmatch(r"[A-Za-z0-9_-][A-Za-z0-9_.-]*", ruta.name) or (
        ruta.name.endswith(".") or PureWindowsPath(ruta.name).is_reserved()
    ):
        raise ValueError("Nombre de archivo no válido")
    return directorio / ruta.name


def copiar(origen: Path, destino: Path):
    base = Path(os.environ.get("INVENTRACK_DB_PATH", "inventrack.sqlite3")).resolve().parent
    fuente_local = _archivo_local(origen, base)
    destino_local = _archivo_local(destino, base)
    if fuente_local.resolve(strict=True) != fuente_local or not fuente_local.is_file():
        raise ValueError("El origen debe ser un archivo regular del directorio de datos")

    with TemporaryDirectory(dir=base) as temporal:
        archivo = Path(temporal) / "copia.sqlite3"
        archivo.touch(mode=0o600, exist_ok=False)
        with closing(sqlite3.connect(fuente_local.as_uri() + "?mode=ro", uri=True)) as fuente:
            with closing(sqlite3.connect(archivo)) as copia:
                fuente.backup(copia)
                if copia.execute("PRAGMA integrity_check").fetchall() != [("ok",)]:
                    raise ValueError("Falló la verificación de integridad de la copia")
        # Publica solo la copia completa. Un destino existente hace fallar link.
        os.link(archivo, destino_local)


if __name__ == "__main__":
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("origen", type=Path)
    cli.add_argument("destino", type=Path)
    argumentos = cli.parse_args()
    copiar(argumentos.origen, argumentos.destino)
