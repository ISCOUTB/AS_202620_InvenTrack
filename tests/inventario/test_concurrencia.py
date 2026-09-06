import pytest
import asyncio
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_concurrencia_20_usuarios_simultaneos():
    """
    Prueba E2E del Reto de Corte 1:
    Simula 20 peticiones concurrentes reduciendo stock sobre el mismo SKU.
    Verifica atomicidad, ausencia de race conditions y consistencia final.
    """
    async with AsyncClient(app=app, base_url="http://test") as ac:
        # 1. Crear producto base con stock inicial de 100 unidades
        prod_resp = await ac.post("/productos/", json={
            "nombre": "SKU-CONCURRENTE", 
            "stock": 100, 
            "precio": 15.0
        })
        assert prod_resp.status_code == 200
        prod_id = prod_resp.json()["id"]

        # 2. Definir corrutina para descontar 1 unidad de stock
        async def descontar_stock():
            return await ac.post("/inventario/movimientos", json={
                "producto_id": prod_id, 
                "cantidad": -1, 
                "tipo": "SALIDA"
            })

        # 3. Disparar 20 peticiones en el mismo loop de eventos asíncronos (al mismo tiempo)
        tasks = [descontar_stock() for _ in range(20)]
        results = await asyncio.gather(*tasks)

        # 4. Validar que todas las peticiones respondieron exitosamente (HTTP 200)
        for response in results:
            assert response.status_code == 200

        # 5. Validar consistencia estricta de stock (100 - 20 = 80 exactos)
        final_resp = await ac.get(f"/productos/{prod_id}")
        assert final_resp.status_code == 200
        assert final_resp.json()["stock"] == 80