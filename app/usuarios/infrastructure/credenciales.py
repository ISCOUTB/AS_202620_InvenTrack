"""Administración local de credenciales individuales de alta entropía."""
import argparse
import hashlib
import os
import secrets
import sqlite3
from contextlib import closing

from app.shared.infrastructure.sqlite import inicializar


def emitir(db, identidad, rol):
    token = secrets.token_urlsafe(32)
    digest = hashlib.sha256(token.encode()).hexdigest()
    db.execute(
        "INSERT INTO usuarios VALUES(?,?,?) ON CONFLICT(id) DO UPDATE SET rol=excluded.rol,digest=excluded.digest",
        (identidad, rol, digest),
    )
    return token


def autenticar(db, cabecera):
    esquema, _, token = cabecera.partition(" ")
    if esquema.lower() != "bearer" or not token:
        return None
    digest = hashlib.sha256(token.encode()).hexdigest()
    return db.execute("SELECT id,rol FROM usuarios WHERE digest=?", (digest,)).fetchone()


def permitido(rol, metodo, ruta):
    if ruta.split("/")[1] == "usuarios":
        return rol == "admin"
    if metodo == "GET" or rol == "admin":
        return True
    return rol == "operador" and metodo == "POST" and ruta.split("/")[1] in {"inventario", "cierres"}


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    sub = cli.add_subparsers(dest="accion", required=True)
    alta = sub.add_parser("emitir")
    alta.add_argument("id")
    alta.add_argument("rol", choices=["admin", "operador", "lector"])
    sub.add_parser("revocar").add_argument("id")
    args = cli.parse_args()
    ruta = os.environ["INVENTRACK_DB_PATH"]
    inicializar(ruta)
    with closing(sqlite3.connect(ruta)) as db, db:
        if args.accion == "emitir":
            token = emitir(db, args.id, args.rol)
            db.commit()
            print(token)
        else:
            db.execute("DELETE FROM usuarios WHERE id=?", (args.id,))


if __name__ == "__main__":
    main()
