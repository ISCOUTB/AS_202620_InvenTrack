"""Una conexión y una transacción por petición. Los adaptadores comparten su contexto."""
import sqlite3
import time
from contextlib import asynccontextmanager, closing, contextmanager, nullcontext
from contextvars import ContextVar
from pathlib import Path

import anyio
from anyio.lowlevel import RunVar

conexion = ContextVar("conexion_sqlite")
actor = ContextVar("actor", default=None)
_escritor = RunVar("turno_escritor_sqlite")
_conexion_escritora = RunVar("conexion_escritora_sqlite")
_ESPERA_SEGUNDOS = 5


class EsperaEscrituraAgotada(Exception):
    pass


@asynccontextmanager
async def _turno_escritura():
    # Una cola por bucle de eventos. SQLite sigue arbitrando entre procesos.
    turno = _escritor.get(None)
    if turno is None:
        turno = anyio.Lock()
        _escritor.set(turno)
    try:
        with anyio.fail_after(_ESPERA_SEGUNDOS):
            await turno.acquire()
    except TimeoutError as exc:
        raise EsperaEscrituraAgotada from exc
    try:
        yield
    finally:
        turno.release()


@contextmanager
def escritor_del_servicio(ruta):
    """Conservar el WAL y las sentencias preparadas durante la vida de la API."""
    with closing(sqlite3.connect(ruta, isolation_level=None, check_same_thread=False)) as db:
        db.execute("PRAGMA foreign_keys=ON")
        token = _conexion_escritora.set((ruta, db))
        try:
            yield
        finally:
            _conexion_escritora.reset(token)

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
CREATE TABLE IF NOT EXISTS proveedores (id TEXT PRIMARY KEY, nombre TEXT NOT NULL, contacto TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS cierres (id TEXT PRIMARY KEY, fecha TEXT NOT NULL, saldos TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS correos_stock (
    evento TEXT PRIMARY KEY, sku TEXT NOT NULL, saldo INTEGER NOT NULL,
    enviado INTEGER NOT NULL DEFAULT 0, intentos INTEGER NOT NULL DEFAULT 0,
    disponible INTEGER NOT NULL DEFAULT 0, turno TEXT
);
CREATE INDEX IF NOT EXISTS correos_pendientes ON correos_stock(enviado, disponible);
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
    limite = time.monotonic() + _ESPERA_SEGUNDOS
    turno = _turno_escritura() if escritura else nullcontext()
    async with turno:
        espera = max(0, limite - time.monotonic())
        compartida = _conexion_escritora.get(None) if escritura else None
        if compartida and compartida[0] == ruta:
            recurso = nullcontext(compartida[1])
        else:
            recurso = closing(sqlite3.connect(ruta, isolation_level=None, check_same_thread=False))
        with recurso as db:
            contexto = conexion.set(db)
            identidad = actor.set(None)
            try:
                db.execute("PRAGMA foreign_keys=ON")
                db.execute(f"PRAGMA busy_timeout={int(espera * 1000)}")
                await anyio.to_thread.run_sync(db.execute, "BEGIN IMMEDIATE" if escritura else "BEGIN")
                yield db
            finally:
                try:
                    db.rollback()
                finally:
                    actor.reset(identidad)
                    conexion.reset(contexto)
