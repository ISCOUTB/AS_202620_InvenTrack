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
