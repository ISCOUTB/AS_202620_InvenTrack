"""Recorrido por la API pública en dos procesos y entrega a SMTP de loopback."""
import os
import socketserver
import ssl
import sqlite3
import subprocess
import sys
import threading
import time
from unittest.mock import MagicMock

import pytest
from contextlib import closing
from email import message_from_bytes, policy

from app.shared.infrastructure.sqlite import inicializar
from app.usuarios.infrastructure.credenciales import emitir
from app.alertas.infrastructure import correo


class ReceptorSMTP(socketserver.StreamRequestHandler):
    def handle(self):
        self.wfile.write(b"220 localhost\r\n")
        while linea := self.rfile.readline():
            comando = linea.split()[0].upper()
            if comando == b"QUIT":
                self.wfile.write(b"221 bye\r\n")
                break
            if comando == b"DATA":
                self.wfile.write(b"354 data\r\n")
                cuerpo = bytearray()
                while (parte := self.rfile.readline()) not in (b".\r\n", b""):
                    cuerpo.extend(parte)
                self.server.mensajes.append(message_from_bytes(cuerpo, policy=policy.default))
            self.wfile.write(b"250 OK\r\n")


def test_reintento_de_correo_conserva_el_evento(tmp_path, monkeypatch):
    ruta = tmp_path / "cola.sqlite3"
    inicializar(ruta)
    with closing(sqlite3.connect(ruta)) as db, db:
        db.execute("INSERT INTO correos_stock(evento,sku,saldo) VALUES('venta','CAFE',5)")
    envios = []

    def enviar(evento, sku, saldo):
        envios.append((evento, sku, saldo))
        if len(envios) == 1:
            raise OSError("Servidor temporalmente inaccesible")

    monkeypatch.setattr(correo, "enviar", enviar)
    monkeypatch.setattr(correo.time, "time", lambda: 100)
    assert correo.despachar_uno(ruta)
    assert not correo.despachar_uno(ruta)
    monkeypatch.setattr(correo.time, "time", lambda: 200)
    assert correo.despachar_uno(ruta)
    assert not correo.despachar_uno(ruta)
    assert envios == [("venta", "CAFE", 5)] * 2


def test_smtp_remoto_exige_certificado_y_nombre_del_servidor(monkeypatch):
    for clave, valor in {"HOST": "smtp.example.test", "DE": "a@example.test",
                         "PARA": "b@example.test", "USUARIO": "", "STARTTLS": "true",
                         "PUERTO": "587"}.items():
        monkeypatch.setenv("INVENTRACK_SMTP_" + clave, valor)
    transporte = MagicMock()
    monkeypatch.setattr(correo.smtplib, "SMTP", transporte)
    correo.enviar("prueba", "CAFE", 5)
    smtp = transporte.return_value.__enter__.return_value
    contexto = smtp.starttls.call_args.kwargs["context"]
    assert contexto.verify_mode == ssl.CERT_REQUIRED
    assert contexto.check_hostname
    monkeypatch.setenv("INVENTRACK_SMTP_STARTTLS", "false")
    with pytest.raises(ValueError, match="requiere STARTTLS"):
        correo.enviar("otra", "CAFE", 4)
    transporte.assert_called_once()


def test_gestion_durable_y_correo(tmp_path):
    ruta = tmp_path / "inventario.sqlite3"
    inicializar(ruta)
    with closing(sqlite3.connect(ruta)) as db, db:
        token = emitir(db, "responsable", "admin")
    entorno = {k: v for k, v in os.environ.items() if not k.startswith("INVENTRACK_SMTP_")}
    entorno.update(INVENTRACK_ENV="production", INVENTRACK_ALLOW_BUSINESS_DATA="true",
                   INVENTRACK_DB_PATH=str(ruta), TOKEN_DE_PRUEBA=token)
    comando = [sys.executable, "-m", "tests.test_gestion_integrada"]
    subprocess.run([*comando, "turno"], env=entorno, check=True, timeout=40)
    with socketserver.TCPServer(("127.0.0.1", 0), ReceptorSMTP) as servidor:
        servidor.mensajes = []
        hilo = threading.Thread(target=servidor.serve_forever, daemon=True)
        hilo.start()
        try:
            entorno.update(INVENTRACK_SMTP_HOST="127.0.0.1", INVENTRACK_SMTP_PUERTO=str(servidor.server_address[1]),
                           INVENTRACK_SMTP_STARTTLS="false", INVENTRACK_SMTP_DE="almacen@example.test",
                           INVENTRACK_SMTP_PARA="encargado@example.test")
            subprocess.run([*comando, "reabrir"], env=entorno, check=True, timeout=35)
        finally:
            servidor.shutdown()
            hilo.join()
        mensaje, = servidor.mensajes
        assert mensaje["To"] == "encargado@example.test"
        assert "CAFE quedó con 10 unidades" in mensaje.get_content()


def durante_turno(cliente):
    assert cliente.get("/sesion").json() == {"rol": "admin"}
    proveedor = cliente.post("/proveedores", json={"nombre": "Cooperativa", "contacto": "Oficina"})
    assert proveedor.status_code == 201
    ruta = "/proveedores/" + proveedor.json()["id"]
    assert cliente.put(ruta, json={"nombre": "Cooperativa del Sur", "contacto": "Luis"}).status_code == 200
    datos = {"id": "caja", "rol": "operador"}
    alta = cliente.post("/usuarios", json=datos)
    assert alta.status_code == 201
    assert alta.headers["cache-control"] == "no-store"
    cabeceras = {"Authorization": "Bearer " + alta.json()["token"]}
    assert cliente.get("/proveedores", headers=cabeceras).status_code == 200
    assert cliente.delete(ruta, headers=cabeceras).status_code == 403
    assert cliente.get("/usuarios", headers=cabeceras).status_code == 403
    assert cliente.get("/usuarios", headers={"Authorization": ""}).status_code == 401
    assert cliente.post("/usuarios", json=datos).status_code == 409
    assert cliente.delete("/usuarios/responsable").status_code == 409
    assert cliente.post("/productos", json={"id": "CAFE", "nombre": "Café"}).status_code == 201
    assert cliente.post("/inventario/CAFE/entradas", headers=cabeceras, json={"cantidad": 14}).status_code == 200
    corte = cliente.post("/cierres", headers=cabeceras)
    assert corte.status_code == 201
    venta = {**cabeceras, "X-Idempotency-Key": "venta-uno"}
    for _ in range(2):
        assert cliente.post("/inventario/CAFE/salidas", headers=venta, json={"cantidad": 4}).json()["stock_final"] == 10
    assert cliente.post("/inventario/CAFE/salidas", headers=cabeceras, json={"cantidad": 1}).status_code == 200
    assert cliente.post("/inventario/CAFE/salidas", headers=cabeceras, json={"cantidad": 100}).status_code == 409
    assert cliente.put("/usuarios/caja/rol", json={"rol": "lector"}).status_code == 200
    assert cliente.post("/cierres", headers=cabeceras).status_code == 403
    token = cliente.post("/usuarios/caja/rotar").json()["token"]
    assert cliente.get("/sesion", headers=cabeceras).status_code == 401
    assert cliente.get("/sesion", headers={"Authorization": "Bearer " + token}).json()["rol"] == "lector"
    assert cliente.delete("/usuarios/caja").status_code == 204
    assert cliente.get("/sesion", headers={"Authorization": "Bearer " + token}).status_code == 401


def tras_reinicio(cliente):
    proveedor, = cliente.get("/proveedores").json()
    assert proveedor["nombre"] == "Cooperativa del Sur"
    assert cliente.delete("/proveedores/" + proveedor["id"]).status_code == 204
    assert cliente.get("/proveedores").json() == []
    movimientos = cliente.get("/inventario/CAFE/movimientos").json()
    assert [(m["tipo"], m["cantidad"], m["actor_id"]) for m in movimientos] == [
        ("salida", 1, "caja"), ("salida", 4, "caja"), ("entrada", 14, "caja")]
    cierre, = cliente.get("/cierres").json()
    ruta = "/cierres/" + cierre["id"] + "/conciliar"
    assert cliente.post(ruta, json={"csv": "sku,cantidad\nCAFE,14"}).json()["diferencias"] == []
    assert cliente.post(ruta, json={"csv": "sku,cantidad\nCAFE,9"}).json()["diferencias"][0]["diferencia"] == -5
    assert cliente.post(ruta, json={"csv": "sku,cantidad\nCAFE,9\nCAFE,2"}).status_code == 422
    with closing(sqlite3.connect(os.environ["INVENTRACK_DB_PATH"])) as db:
        limite = time.monotonic() + 12
        while db.execute("SELECT enviado FROM correos_stock").fetchall() != [(1,)]:
            assert time.monotonic() < limite, "El SMTP local no recibió la alerta en el plazo"
            time.sleep(0.05)


if __name__ == "__main__":
    from fastapi.testclient import TestClient
    from app.main import app

    with TestClient(app, headers={"Authorization": "Bearer " + os.environ["TOKEN_DE_PRUEBA"]}) as cliente:
        if sys.argv[1] == "turno":
            durante_turno(cliente)
        else:
            tras_reinicio(cliente)
