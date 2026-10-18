import pytest
import asyncio
import math
import time
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_concurrencia_20_usuarios_simultaneos():

    async with AsyncClient(
        transport=ASGITransport(app=app), 
        base_url="http://test",
        follow_redirects=True
    ) as ac:
        prod_id = "prod-conc-001"

        # 0. El producto debe existir y estar activo en `productos` antes de
        #    que `inventario` acepte movimientos sobre él (ADR-0003).
        producto_resp = await ac.post(
            "/productos", json={"id": prod_id, "nombre": "Producto de prueba de concurrencia"}
        )
        assert producto_resp.status_code == 201, f"No se pudo crear el producto: {producto_resp.json()}"

        # 1. Cargar stock inicial de 100 unidades mediante el endpoint de entradas
        ingreso_resp = await ac.post(f"/inventario/{prod_id}/entradas", json={"cantidad": 100})
        assert ingreso_resp.status_code == 200, f"Error preparando stock inicial: {ingreso_resp.json()}"

        # 2. Definir corrutina para realizar una salida de 1 unidad
        async def descontar_stock():
            started = time.perf_counter()
            response = await ac.post(f"/inventario/{prod_id}/salidas", json={"cantidad": 1})
            return response, time.perf_counter() - started

        # 3. Disparar 20 peticiones concurrentes en el event loop
        tasks = [descontar_stock() for _ in range(20)]
        results = await asyncio.gather(*tasks)

        # 4. Validar que todas las peticiones devolvieron HTTP 200 OK
        for response, _ in results:
            assert response.status_code == 200, f"Fallo en salida ({response.status_code}): {response.json()}"

        latencies = sorted(duration for _, duration in results)
        p95_index = max(1, math.ceil(len(latencies) * 0.95)) - 1
        assert latencies[p95_index] <= 0.4

        # 5. Validar que la consulta final refleje exactamente 80 unidades de stock
        consulta_resp = await ac.get(f"/inventario/{prod_id}")
        assert consulta_resp.status_code == 200
        assert consulta_resp.json()["cantidad"] == 80