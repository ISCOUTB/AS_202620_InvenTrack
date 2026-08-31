from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_corte_vertical_eliminar_producto_sin_movimientos():
    client.post("/productos", json={"id": "api-p1", "nombre": "Café 250g"})

    response = client.delete("/productos/api-p1")

    assert response.status_code == 200
    body = response.json()
    assert body["eliminado_fisicamente"] is True
    assert body["desactivado"] is False


def test_corte_vertical_eliminar_producto_con_movimientos_lo_desactiva():
    client.post("/productos", json={"id": "api-p2", "nombre": "Azúcar 1kg"})
    client.post("/productos/api-p2/_marcar-con-movimientos")

    response = client.delete("/productos/api-p2")

    assert response.status_code == 200
    body = response.json()
    assert body["eliminado_fisicamente"] is False
    assert body["desactivado"] is True
    assert "ESC-02" in body["mensaje"]


def test_corte_vertical_eliminar_producto_inexistente_da_404():
    response = client.delete("/productos/no-existe")

    assert response.status_code == 404
