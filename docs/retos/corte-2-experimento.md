# Reporte de Experimento Operativo — Segundo Corte (S10): Concurrencia de Negocio en Inventario

## 1. Caracterización del Escenario Operativo
- **Escenario:** Alta concurrencia transaccional sobre el dominio de inventario (Evolución de ESC-01 / ESC-04).
- **Justificación:** Demostrar que el MVP desplegado soporta ráfagas de peticiones simultáneas sobre un mismo producto (SKU) ejecutando lógica de negocio transaccional real (descuento atómico de stock), manteniendo la latencia percentil 95 en estado caliente por debajo del umbral crítico sin recurrir a sondas estáticas de salud (`/health`).

## 2. Hipótesis del Experimento
> *"Si se ejecutan 20 peticiones HTTP concurrentes de salida de inventario (`POST /inventario/{sku}/salidas`) sobre el mismo producto utilizando el mecanismo de exclusión mutua asíncrona por SKU (`asyncio.Lock`), entonces el sistema garantizará la consistencia estricta del stock (cero condiciones de carrera o valores negativos) y un tiempo de respuesta en el percentil 95 ($p95$) menor o igual a **400 ms**, sin comprometer la estabilidad del monolito modular."*

## 3. Montaje y Variables del Experimento
- **Entorno de Ejecución:** Entorno de pruebas asíncrono sobre la API de FastAPI (`tests/inventario/test_concurrencia.py`).
- **Variables Independientes:** 
  - Concurrencia: 20 clientes simulados simultáneos.
  - Recurso crítico: El mismo identificador de producto (`prod-conc-001`).
- **Variables Dependientes:**
  - Latencia de respuesta de los endpoints de negocio (`/salidas`).
  - Integridad del stock final (Esperado: 80 unidades a partir de un stock inicial de 100 descontando 20 unidades de a 1).
  - Tasa de éxito HTTP (Código esperado: 200 OK).

## 4. Ejecución del Montaje (Flujo de Negocio Real)
La prueba automatizada simula el flujo completo del dominio sin usar adaptadores simulados superficiales:
1. Creación del producto en el módulo `productos` (validando contratos y dependencias de arquitectura hexagonal).
2. Carga de un stock inicial de 100 unidades mediante el endpoint de entradas de `inventario`.
3. Disparo masivo de 20 peticiones concurrentes de salida de 1 unidad cada una mediante `asyncio.gather`.

La prueba mide el tiempo de cada `POST /inventario/{sku}/salidas` con
`time.perf_counter()`, calcula el p95 mediante rango más cercano y falla si el
resultado supera 400 ms. Por tanto, la medición ejercita una operación real de
inventario y no una sonda de salud.

## 5. Resultados y Contraste con el Umbral
- **Latencia $p95$ medida:** se obtiene en cada ejecución de
  `tests/inventario/test_concurrencia.py` sobre las 20 salidas reales; la prueba
  exige que sea menor o igual a 400 ms.
- **Integridad del Stock:** Stock inicial de 100 unidades, stock final exacto de **80 unidades** (cero descuadres).
- **Tasa de Éxito:** 100% de peticiones atendidas correctamente con código HTTP 200 OK.
- **Resiliencia ante saturación:** El cerrojo asíncrono encola las peticiones de manera ordenada; ante tiempos de espera excesivos, degrada controladamente respondiendo HTTP 503 sin corromper la memoria.

La entrega anterior reportó 28 ms, pero no conserva una serie de observaciones
ni un artefacto ejecutable que permita reconstruir esa cifra exacta. Se conserva
como referencia histórica, no como línea base verificable. La línea base
cuantitativa antes del lock queda pendiente porque ese estado no está disponible
en el historial evaluado; no se inventa una cifra retrospectiva.

## 6. Conclusión y Consecuencias Arquitectónicas
El experimento valida empíricamente que el diseño de monolito modular con puertos, adaptadores y exclusión mutua por SKU resuelve el reto de consistencia transaccional del MVP con un costo de infraestructura cero (C5). Como deuda técnica conocida (documentada en arc42 §11), este almacenamiento en memoria es transitorio y requerirá persistencia relacional transaccional ante despliegues con múltiples réplicas horizontales.