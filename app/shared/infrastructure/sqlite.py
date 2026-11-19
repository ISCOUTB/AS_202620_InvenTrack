"""Una conexión y una transacción por petición. Los adaptadores comparten su contexto."""
import asyncio
import sqlite3
from contextlib import asynccontextmanager
from contextvars import ContextVar
from pathlib import Path

conexion = ContextVar("conexion_sqlite")
actor = ContextVar("actor", default=None)

ESQUEMA = """
CREATE TABLE IF NOT EXISTS usuarios (
    id TEXT PRIMARY KEY, rol TEXT NOT NULL CHECK(rol IN ('admin','operador','lector')),
    digest TEXT UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS productos (id TEXT PRIMARY KEY, nombre TEXT NOT NULL, activo INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS stocks (
    producto_id TEXT PRIMARY KEY REFERENCES productos(id), cantidad INTEGER NOT NULL CHECK(cantidad >= 0)
);
CREATE TABLE IF NOT EXISTS movimientos (
    producto_id TEXT NOT NULL REFERENCES productos(id), tipo TEXT NOT NULL, cantidad INTEGER NOT NULL,
    registrado_en TEXT NOT NULL, actor_id TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS movimientos_sku ON movimientos(producto_id);
CREATE TABLE IF NOT EXISTS comandos (
    actor_id TEXT NOT NULL, clave TEXT NOT NULL, huella TEXT NOT NULL, resultado TEXT NOT NULL,
    PRIMARY KEY(actor_id, clave)
);
CREATE TABLE IF NOT EXISTS auditoria (evento_id TEXT PRIMARY KEY, evento TEXT NOT NULL);
"""


def inicializar(ruta):
    if not ruta or ruta == ":memory:":
        raise ValueError("Se requiere un archivo SQLite")
    try:
        Path(ruta).touch(mode=0o600, exist_ok=False)
    except FileExistsError:
        pass
    db = sqlite3.connect(ruta)
    try:
        db.execute("PRAGMA journal_mode=WAL")
        db.executescript(ESQUEMA)
    finally:
        db.close()


@asynccontextmanager
async def transaccion(ruta, escritura):
    db = sqlite3.connect(ruta, isolation_level=None, check_same_thread=False)
    contexto = conexion.set(db)
    identidad = actor.set(None)
    try:
        db.execute("PRAGMA foreign_keys=ON")
        await asyncio.to_thread(db.execute, "BEGIN IMMEDIATE" if escritura else "BEGIN")
        yield db
    finally:
        actor.reset(identidad)
        conexion.reset(contexto)
        db.close()  # Revierte cualquier operación sin commit.
