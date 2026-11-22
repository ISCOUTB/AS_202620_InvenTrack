"""Cola de correo del perfil durable. El envío ocurre después del commit de inventario."""
import asyncio
import logging
import os
import smtplib
import sqlite3
import ssl
import time
from contextlib import closing
from email.message import EmailMessage
from uuid import uuid4

UMBRAL_BAJO = 10
logger = logging.getLogger(__name__)


def registrar_cruce(db, evento):
    datos = evento["data"]
    if datos["tipo"] != "SALIDA":
        return
    final = datos["stock_final"]
    if final <= UMBRAL_BAJO < final + datos["cantidad"]:
        db.execute("INSERT INTO correos_stock(evento,sku,saldo) VALUES(?,?,?)",
                   (evento["event_id"], datos["producto_id"], final))


def correo_configurado():
    return all(os.getenv("INVENTRACK_SMTP_" + k) for k in ("HOST", "DE", "PARA"))


def enviar(evento, sku, saldo):
    mensaje = EmailMessage()
    mensaje["From"] = os.environ["INVENTRACK_SMTP_DE"]
    mensaje["To"] = os.environ["INVENTRACK_SMTP_PARA"]
    mensaje["Subject"] = "InvenTrack · stock bajo"
    mensaje["Message-ID"] = f"<{evento}@inventrack>"
    mensaje.set_content(f"El producto {sku} quedó con {saldo} unidades. Umbral de aviso: {UMBRAL_BAJO}.")
    tls = os.getenv("INVENTRACK_SMTP_STARTTLS", "true").lower() == "true"
    usuario = os.getenv("INVENTRACK_SMTP_USUARIO")
    if usuario and not tls:
        raise ValueError("La autenticación SMTP requiere STARTTLS")
    with smtplib.SMTP(os.environ["INVENTRACK_SMTP_HOST"],
                      int(os.getenv("INVENTRACK_SMTP_PUERTO", "587")), timeout=10) as smtp:
        if tls:
            smtp.starttls(context=ssl.create_default_context())
        if usuario:
            smtp.login(usuario, os.environ["INVENTRACK_SMTP_CLAVE"])
        smtp.send_message(mensaje)


def despachar_uno(ruta):
    ahora = int(time.time())
    turno = str(uuid4())
    with closing(sqlite3.connect(ruta, isolation_level=None)) as db:
        fila = db.execute("""
            UPDATE correos_stock SET turno=?, disponible=?, intentos=intentos+1
            WHERE evento=(SELECT evento FROM correos_stock WHERE enviado=0 AND disponible<=?
                          ORDER BY disponible,rowid LIMIT 1)
            RETURNING evento,sku,saldo,intentos
        """, (turno, ahora + 120, ahora)).fetchone()
        if fila is None:
            return False
        evento, sku, saldo, intentos = fila
        try:
            enviar(evento, sku, saldo)
        except (OSError, smtplib.SMTPException, KeyError, ValueError) as exc:
            logger.warning("Correo de inventario pendiente (%s)", type(exc).__name__)
            db.execute("UPDATE correos_stock SET disponible=? WHERE evento=? AND turno=?",
                       (int(time.time()) + min(3600, 10 * 2 ** min(intentos, 9)), evento, turno))
        else:
            db.execute("UPDATE correos_stock SET enviado=1 WHERE evento=? AND turno=?", (evento, turno))
        return True


async def procesar_cola(ruta):
    while True:
        try:
            procesado = await asyncio.to_thread(despachar_uno, ruta)
        except sqlite3.Error:
            logger.exception("No se pudo consultar la cola de correo")
            procesado = False
        if not procesado:
            await asyncio.sleep(5)
