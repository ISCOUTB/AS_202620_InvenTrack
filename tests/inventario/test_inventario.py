from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_entrada_y_consulta_de_stock():
    client.post("/productos", json={"id": "p-100", "nombre": "Producto 100"})

    response = client.post("/inventario/p-100/entradas", json={"cantidad": 10})
    assert response.status_code == 200
    body = response.json()
    assert body["producto_id"] == "p-100"
    assert body["stock_final"] == 10

    response = client.get("/inventario/p-100")
    assert response.status_code == 200
    assert response.json()["cantidad"] == 10


def test_salida_valida_resta_stock():
    client.post("/productos", json={"id": "p-200", "nombre": "Producto 200"})
    client.post("/inventario/p-200/entradas", json={"cantidad": 8})

    response = client.post("/inventario/p-200/salidas", json={"cantidad": 3})
    assert response.status_code == 200
    assert response.json()["stock_final"] == 5


def test_salida_mayor_que_stock_rechaza():
    client.post("/productos", json={"id": "p-300", "nombre": "Producto 300"})
    client.post("/inventario/p-300/entradas", json={"cantidad": 2})

    response = client.post("/inventario/p-300/salidas", json={"cantidad": 5})
    assert response.status_code == 409


def test_salida_sin_stock_registrado_rechaza():
    client.post("/productos", json={"id": "p-350", "nombre": "Producto 350"})

    response = client.post("/inventario/p-350/salidas", json={"cantidad": 1})
    assert response.status_code == 404


def test_movimiento_sobre_producto_inexistente_rechaza():
    # ADR-0003: inventario ya no acepta movimientos para productos que no
    # existen (o no están activos) en el módulo productos.
    response = client.post("/inventario/no-existe/entradas", json={"cantidad": 1})
    assert response.status_code == 404