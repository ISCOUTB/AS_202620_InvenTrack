import asyncio

import httpx
import pytest
from fastapi.testclient import TestClient

from app.main import _broker_mensajeria, _idempotency_store, app

client = TestClient(app)


def test_entrada_publica_evento_de_auditoria_con_trazabilidad():
    _broker_mensajeria.audit_log.clear()
    _broker_mensajeria.processed_events.clear()
    _idempotency_store.clear()

    client.post("/productos", json={"id": "p-evento", "nombre": "Producto evento"})
    response = client.post(
        "/inventario/p-evento/entradas",
        headers={
            "X-Correlation-ID": "corr-real-001",
            "X-Idempotency-Key": "cmd-real-001",
        },
        json={"cantidad": 4},
    )

    assert response.status_code == 200
    assert _broker_mensajeria.audit_log[-1]["status"] == "PROCESSED_SUCCESS"
    assert _broker_mensajeria.audit_log[-1]["correlation_id"] == "corr-real-001"
    assert len(_broker_mensajeria.processed_events) == 1
    evento = _broker_mensajeria.published_messages[-1]
    assert evento["idempotency_key"] == "cmd-real-001"
    assert evento["data"]["tipo"] == "ENTRADA"
    metricas = client.get("/metrics").text
    assert 'inventrack_messaging_messages_total{status="processed"}' in metricas


def test_repetir_post_con_la_misma_clave_no_repite_el_movimiento():
    _idempotency_store.clear()
    _broker_mensajeria.published_messages.clear()
    client.post("/productos", json={"id": "p-idempotente", "nombre": "Producto idempotente"})

    headers = {"X-Idempotency-Key": "cmd-idempotente"}
    primera = client.post(
        "/inventario/p-idempotente/entradas",
        headers=headers,
        json={"cantidad": 5},
    )
    segunda = client.post(
        "/inventario/p-idempotente/entradas",
        headers=headers,
        json={"cantidad": 5},
    )

    assert primera.status_code == 200
    assert segunda.status_code == 200
    assert segunda.json() == primera.json()
    assert client.get("/inventario/p-idempotente").json()["cantidad"] == 5
    assert len(_broker_mensajeria.published_messages) == 1


def test_reutilizar_clave_con_payload_diferente_rechaza():
    _idempotency_store.clear()
    client.post("/productos", json={"id": "p-conflicto", "nombre": "Producto conflicto"})
    headers = {"X-Idempotency-Key": "cmd-conflicto"}

    primera = client.post(
        "/inventario/p-conflicto/entradas",
        headers=headers,
        json={"cantidad": 2},
    )
    segunda = client.post(
        "/inventario/p-conflicto/entradas",
        headers=headers,
        json={"cantidad": 3},
    )

    assert primera.status_code == 200
    assert segunda.status_code == 409
    assert client.get("/inventario/p-conflicto").json()["cantidad"] == 2


@pytest.mark.asyncio
async def test_posts_concurrentes_con_la_misma_clave_aplican_un_solo_movimiento():
    _idempotency_store.clear()
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as async_client:
        await async_client.post(
            "/productos",
            json={"id": "p-concurrente-idempotente", "nombre": "Producto concurrente"},
        )
        headers = {"X-Idempotency-Key": "cmd-concurrente"}
        respuestas = await asyncio.gather(
            async_client.post(
                "/inventario/p-concurrente-idempotente/entradas",
                headers=headers,
                json={"cantidad": 7},
            ),
            async_client.post(
                "/inventario/p-concurrente-idempotente/entradas",
                headers=headers,
                json={"cantidad": 7},
            ),
        )
        stock = await async_client.get("/inventario/p-concurrente-idempotente")

    assert [respuesta.status_code for respuesta in respuestas] == [200, 200]
    assert respuestas[0].json() == respuestas[1].json()
    assert stock.json()["cantidad"] == 7


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


def test_entrada_con_cantidad_no_positiva_rechaza_en_http():
    client.post("/productos", json={"id": "p-400", "nombre": "Producto 400"})

    for cantidad in (0, -1):
        response = client.post("/inventario/p-400/entradas", json={"cantidad": cantidad})
        assert response.status_code == 422


def test_salida_con_cantidad_no_positiva_rechaza_en_http():
    client.post("/productos", json={"id": "p-500", "nombre": "Producto 500"})

    for cantidad in (0, -1):
        response = client.post("/inventario/p-500/salidas", json={"cantidad": cantidad})
        assert response.status_code == 422