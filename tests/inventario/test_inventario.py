import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_entrada_y_consulta_de_stock():
    response = client.post("/inventario/p-100/entradas", json={"cantidad": 10})
    assert response.status_code == 200
    body = response.json()
    assert body["producto_id"] == "p-100"
    assert body["stock_final"] == 10

    response = client.get("/inventario/p-100")
    assert response.status_code == 200
    assert response.json()["cantidad"] == 10


def test_salida_valida_resta_stock():
    client.post("/inventario/p-200/entradas", json={"cantidad": 8})

    response = client.post("/inventario/p-200/salidas", json={"cantidad": 3})
    assert response.status_code == 200
    assert response.json()["stock_final"] == 5


def test_salida_mayor_que_stock_rechaza():
    client.post("/inventario/p-300/entradas", json={"cantidad": 2})

    response = client.post("/inventario/p-300/salidas", json={"cantidad": 5})
    assert response.status_code == 409


def test_salida_sin_stock_registrado_rechaza():
    response = client.post("/inventario/p-404/salidas", json={"cantidad": 1})
    assert response.status_code == 404
