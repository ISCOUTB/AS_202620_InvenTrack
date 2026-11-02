from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_check_responde_ok() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "InvenTrack"}


def test_metrics_expone_contador_prometheus() -> None:
    client.get("/health")

    response = client.get("/metrics")

    assert response.status_code == 200
    assert "inventrack_http_requests_total" in response.text
    assert 'method="GET",path="/health"' in response.text


def test_produccion_bloquea_superficies_internas_y_datos(monkeypatch) -> None:
    monkeypatch.setenv("INVENTRACK_ENV", "production")
    monkeypatch.delenv("INVENTRACK_INTERNAL_TOKEN", raising=False)
    monkeypatch.setenv("INVENTRACK_ALLOW_BUSINESS_DATA", "false")

    for path in ("/metrics", "/docs", "/redoc", "/openapi.json"):
        assert client.get(path).status_code == 404

    assert client.get("/productos").status_code == 503
    assert client.get("/inventario/test-producto").status_code == 503
    assert (
        client.post(
            "/inventario/test-producto/entradas",
            json={"cantidad": 1},
        ).status_code
        == 503
    )


def test_produccion_permite_superficies_internas_con_token_interno(monkeypatch) -> None:
    monkeypatch.setenv("INVENTRACK_ENV", "production")
    monkeypatch.setenv("INVENTRACK_INTERNAL_TOKEN", "test-token")

    headers = {"X-Internal-Token": "test-token"}
    for path in ("/metrics", "/docs", "/redoc", "/openapi.json"):
        assert client.get(path, headers=headers).status_code == 200
