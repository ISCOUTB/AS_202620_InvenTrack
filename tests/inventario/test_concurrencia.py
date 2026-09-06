import pytest
import asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_concurrencia_20_usuarios_simultaneos():
    """
    Prueba E2E del Reto de Corte 1:
    Simula 20 peticiones concurrentes reduciendo stock sobre el mismo SKU.
    Verifica atomicidad, ausencia de race conditions y consistencia final.
    """
    async with AsyncClient(
        transport=ASGITransport(app=app), 
        base_url="http://test",
        follow_redirects=True
    ) as ac:
        # 1. Crear producto base
        prod_payload = {
            "id": "prod-conc-001",
            "nombre": "SKU-CONCURRENTE", 
            "descripcion": "Producto de prueba de concurrencia",
            "precio": 15.0,
            "stock": 100
        }
        
        prod_resp = await ac.post("/productos/", json=prod_payload)
        
        if prod_resp.status_code not in (200, 201):
            pytest.fail(f"Error creando producto ({prod_resp.status_code}): {prod_resp.json()}")

        prod_id = prod_resp.json()["id"]

        # 2. Definir corrutina para registrar movimiento de salida
        async def descontar_stock():
            return await ac.post("/inventario", json={
                "producto_id": prod_id, 
                "cantidad": 1, 
                "tipo": "SALIDA"
            })

        # 3. Disparar 20 peticiones concurrentes
        tasks = [descontar_stock() for _ in range(20)]
        results = await asyncio.gather(*tasks)

        # 4. Validar respuestas exitosas
        for response in results:
            assert response.status_code in (200, 201), f"Fallo en movimiento ({response.status_code}): {response.json()}"

        # 5. Validar consistencia de stock final (100 - 20 = 80 exactos)
        final_resp = await ac.get(f"/productos/{prod_id}")
        assert final_resp.status_code == 200
        assert final_resp.json()["stock"] == 80