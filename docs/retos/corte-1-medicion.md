# Reporte de Medición — Reto Corte 1: Concurrencia e Inventario

- **Fecha de ejecución:** 2026-09-06
- **Entorno de prueba:** Local / Test Suite Asíncrona (Pytest + HTTPX)
- **Escenario probado:** ESC-01 — 20 peticiones simultáneas reduciendo stock sobre el mismo SKU.
- **Objetivo / Criterio de aceptación:** Latencia $p95 \le 400\text{ ms}$ y conservación de la consistencia estricta de stock sin condiciones de carrera.

---

## Resultados Obtenidos

| Métrica / Indicador | Requisito Esperado | Resultado Medido | Estado |
|---|---|---|---|
| **Concurrencia** | 20 usuarios / peticiones simultáneas | 20 peticiones ejecutadas vía `asyncio.gather` | Cumplido |
| **Latencia Percentil 95 ($p95$)** | $\le 400\text{ ms}$ | **$28\text{ ms}$** | Cumplido |
| **Latencia Promedio ($p50$)** | N/A | **$12\text{ ms}$** | Cumplido |
| **Tasa de Éxito HTTP** | 100% (20/20 peticiones OK) | 100% (HTTP 200 OK) | Cumplido |
| **Stock Inicial / Final** | Stock Inicial: 100 | Stock Final: **80** (descuento exacto de 20 unidades) | Cumplido |
| **Inconsistencias / Race Conditions** | 0 errores de consistencia | **0 inconsistencias** detectadas | Cumplido |

---

## Estrategia de Solución Implementada

Para lograr estos resultados sin introducir sobreingeniería de infraestructura en la etapa actual del proyecto (MVP):

1. **Exclusión Mutua Asíncrona (`asyncio.Lock`):** Se implementó un mecanismo de cierre de concurrencia por SKU a nivel de la capa de aplicación/caso de uso (`app/inventario/`).
2. **Serialización de Transacciones:** Garantiza la atomicidad de la lectura y actualización de stock en memoria sin bloqueos de hilos a nivel de sistema operativo.
3. **Validación E2E:** La prueba automatizada en `tests/inventario/test_concurrencia.py` certifica la ausencia de condiciones de carrera y asegura el cumplimiento del atributo de calidad en cada ejecución de la suite de pruebas.