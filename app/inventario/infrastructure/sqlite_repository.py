import json
from dataclasses import asdict
from datetime import datetime

from app.inventario.application.registrar_movimiento import MovimientoInventarioResult
from app.inventario.domain.movimiento import Movimiento
from app.inventario.domain.ports import MovimientoRepository, StockRepository
from app.inventario.domain.stock import StockProducto
from app.inventario.infrastructure.idempotency import IdempotencyConflictError, IdempotentResult
from app.shared.infrastructure.sqlite import actor, conexion


class StockSQLite(StockRepository):
    def obtener(self, producto_id):
        fila = conexion.get().execute("SELECT producto_id,cantidad FROM stocks WHERE producto_id=?", (producto_id,)).fetchone()
        return StockProducto(*fila) if fila else None

    def guardar(self, stock):
        if stock.cantidad > 2**63 - 1:
            raise ValueError("La cantidad supera la capacidad del inventario durable.")
        conexion.get().execute(
            "INSERT INTO stocks VALUES(?,?) ON CONFLICT(producto_id) DO UPDATE SET cantidad=excluded.cantidad",
            (stock.producto_id, stock.cantidad),
        )

    def listar(self):
        return [StockProducto(*r) for r in conexion.get().execute("SELECT producto_id,cantidad FROM stocks")]


class MovimientosSQLite(MovimientoRepository):
    def registrar(self, movimiento):
        conexion.get().execute(
            "INSERT INTO movimientos VALUES(?,?,?,?,?)",
            (movimiento.producto_id, movimiento.tipo, movimiento.cantidad, movimiento.registrado_en.isoformat(), actor.get()),
        )

    def tiene_movimientos(self, producto_id):
        return conexion.get().execute("SELECT 1 FROM movimientos WHERE producto_id=? LIMIT 1", (producto_id,)).fetchone() is not None

    def listar_por_producto(self, producto_id):
        filas = conexion.get().execute(
            "SELECT producto_id,tipo,cantidad,registrado_en,actor_id FROM movimientos WHERE producto_id=? ORDER BY rowid", (producto_id,)
        )
        return [Movimiento(i, t, c, datetime.fromisoformat(f), a) for i, t, c, f, a in filas]


class IdempotenciaSQLite:
    async def execute(self, key, fingerprint, operation):
        if key is None:
            return IdempotentResult(await operation(), False)
        db = conexion.get()
        huella = json.dumps(fingerprint)
        identidad = actor.get()
        anterior = db.execute("SELECT huella,resultado FROM comandos WHERE actor_id=? AND clave=?", (identidad, key)).fetchone()
        if anterior:
            if huella != anterior[0]:
                raise IdempotencyConflictError("La clave de idempotencia ya fue usada con otro comando")
            return IdempotentResult(MovimientoInventarioResult(**json.loads(anterior[1])), True)
        resultado = await operation()
        db.execute("INSERT INTO comandos VALUES(?,?,?,?)", (identidad, key, huella, json.dumps(asdict(resultado))))
        return IdempotentResult(resultado, False)


def guardar_evento(evento):
    evento["actor_id"] = actor.get()
    conexion.get().execute("INSERT INTO auditoria VALUES(?,?)", (evento["event_id"], json.dumps(evento)))
