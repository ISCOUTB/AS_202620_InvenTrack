# Reporte de Medición — Reto Corte 1: Concurrencia e Inventario

- **Fecha de ejecución:** 2026-09-06
- **Entorno de prueba:** Local / Test Suite Asíncrona (Pytest + HTTPX)
- **Escenario probado:** ESC-01 — 20 peticiones simultáneas reduciendo stock sobre el mismo SKU.
- **Objetivo / Criterio de aceptación:** Latencia $p95 \le 400\text{ ms}$ y conservación de la consistencia estricta de stock sin condiciones de carrera.

---

## 1. Diagnóstico del Reto

Para cumplir con la distinción técnica exigida por la asignatura, el problema abordado en este reto se desglosa formalmente de la siguiente manera:

* **Síntoma:** Ante solicitudes simultáneas sobre el mismo producto, las lecturas y escrituras entrelazadas generaban inconsistencias en el stock final o el registro de valores negativos.
* **Causa Raíz:** Ausencia de un mecanismo de exclusión mutua / serialización asíncrona sobre el repositorio en memoria durante operaciones de actualización de stock.
* **Riesgo Prioritario:** Pérdida de integridad en el dato central del negocio (inventario) y corrupción de saldos por lecturas sucias (*dirty reads*).
* **Línea Base Verificable:** La ejecución previa sin control de concurrencia permitía condiciones de carrera (*race conditions*). Se estableció el umbral objetivo en ráfagas de 20 peticiones simultáneas con latencia $p95 \le 400\text{ ms}$ y 0 descuadres en el inventario.

---

## 2. Resultados Obtenidos

| Métrica / Indicador | Requisito Esperado | Resultado Medido | Estado |
|---|---|---|---|
| **Concurrencia** | 20 usuarios / peticiones simultáneas | 20 peticiones ejecutadas vía `asyncio.gather` | Cumplido |
| **Latencia Percentil 95 ($p95$)** | $\le 400\text{ ms}$ | **$28\text{ ms}$** | Cumplido |
| **Latencia Promedio ($p50$)** | N/A | **$12\text{ ms}$** | Cumplido |
| **Tasa de Éxito HTTP** | 100% (20/20 peticiones OK) | 100% (HTTP 200 OK) | Cumplido |
| **Stock Inicial / Final** | Stock Inicial: 100 | Stock Final: **80** (descuento exacto de 20 unidades) | Cumplido |
| **Inconsistencias / Race Conditions** | 0 errores de consistencia | **0 inconsistencias** detectadas | Cumplido |

---

## 3. Estrategia de Solución Implementada

Para lograr estos resultados sin introducir sobreingeniería de infraestructura en la etapa actual del proyecto (MVP):

1. **Exclusión Mutua Asíncrona (`asyncio.Lock`):** Se implementó un mecanismo de cierre de concurrencia por SKU a nivel de la capa de aplicación/caso de uso (`app/inventario/`).
2. **Serialización de Transacciones:** Garantiza la atomicidad de la lectura y actualización de stock en memoria sin bloqueos de hilos a nivel de sistema operativo.
3. **Validación E2E:** La prueba automatizada en `tests/inventario/test_concurrencia.py` certifica la ausencia de condiciones de carrera y asegura el cumplimiento del atributo de calidad en cada ejecución de la suite de pruebas.

---

## 4. Degradación Controlada y Resiliencia

Ante picos extraordinarios de tráfico o la saturación del cerrojo asíncrono:

* **Encolamiento eficiente:** Las transacciones se encolan de forma ordenada en el *event loop* asíncrono de FastAPI sin bloquear la ejecución global del servidor.
* **Manejo de Saturación:** Si el tiempo de espera por el *lock* excede el umbral tolerado o se agotan los recursos de concurrencia, el sistema degrada respondiendo con estados HTTP `429 Too Many Requests` o `503 Service Unavailable`, garantizando que ninguna transacción a mitad de ejecución corrompa el stock.

---

## 5. Instrucciones para Reproducir la Medición

Para verificar de forma autónoma estos resultados dentro del repositorio:

```bash
# 1. Activar el entorno virtual e instalar dependencias
source .venv/bin/activate
pip install -r requirements.txt

# 2. Ejecutar la prueba específica de concurrencia e inventario
pytest tests/inventario/test_concurrencia.py -v