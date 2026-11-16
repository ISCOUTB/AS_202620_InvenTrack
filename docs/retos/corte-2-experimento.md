# Reporte de Experimento Operativo — Segundo Corte (S10): Concurrencia de Negocio en Inventario

> **Commit de la evidencia actual:** `a5cd1d8bff1ebac701ba8b682c512929f888a459`
> — 2026-11-13T18:53:47-05:00.

## 1. Caracterización del Escenario Operativo
- **Escenario medido:** **ESC-01** (principal). La prueba registra 20 salidas
  simultáneas sobre el mismo SKU y verifica consistencia exacta. También aporta
  evidencia parcial para **ESC-04**, porque mide p95 de una operación de negocio
  bajo concurrencia; no mide consultas de catálogo/listado ni una carga sostenida
  de 20 solicitudes por segundo como describe ESC-04.
- **Justificación:** Demostrar que el MVP desplegado soporta ráfagas de peticiones simultáneas sobre un mismo producto (SKU) ejecutando lógica de negocio transaccional real (descuento atómico de stock), manteniendo la latencia percentil 95 en estado caliente por debajo del umbral crítico sin recurrir a sondas estáticas de salud (`/health`).

## 2. Hipótesis del Experimento
> *"Si se ejecutan 20 peticiones HTTP concurrentes de salida de inventario (`POST /inventario/{sku}/salidas`) sobre el mismo producto utilizando el mecanismo de exclusión mutua asíncrona por SKU (`asyncio.Lock`), entonces el sistema garantizará la consistencia estricta del stock (cero condiciones de carrera o valores negativos) y un tiempo de respuesta en el percentil 95 ($p95$) menor o igual a **400 ms**, sin comprometer la estabilidad del monolito modular."*

## 3. Montaje y Variables del Experimento
- **Entorno de Ejecución:** Local, dentro del proceso de pruebas, usando
  `httpx.AsyncClient` con `ASGITransport` contra la aplicación FastAPI; no es una
  medición del despliegue público ni de una imagen Docker.
- **Hardware/software:** Python 3.11, FastAPI/Uvicorn del lock vigente,
  Windows y repositorios en memoria. La prueba no abre un socket ni atraviesa
  red externa.
- **Calentamiento:** Se crea el producto y se carga el stock inicial antes de
  iniciar el cronómetro. No se ejecutan peticiones de calentamiento separadas;
  por tanto, el resultado representa estado caliente del proceso de prueba, no
  cold start.
- **Repeticiones históricas:** Una ejecución documentada el 2026-11-06.
- **Repeticiones actuales:** Cinco ejecuciones independientes de 20 solicitudes
  cada una, realizadas el 2026-11-15. Sus latencias individuales están en
  [resultados-concurrencia-2026-11-15.json](resultados-concurrencia-2026-11-15.json).
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

El artefacto versionado conserva las observaciones individuales de las cinco
ejecuciones actuales. Las observaciones de la ejecución histórica del 6 de
noviembre no se conservaron y no se reconstruyen retrospectivamente.

## 5. Resultados y Contraste con el Umbral
- **Latencia $p95$ medida:** **32.891 ms** en una ejecución reproducible de
  20 salidas reales. El umbral del escenario es **400 ms**; por tanto, el
  resultado cumple con un margen de **367.109 ms** (el p95 medido es
  aproximadamente 12.2 veces menor que el límite).
- **Integridad del Stock:** Stock inicial de 100 unidades, stock final exacto de **80 unidades** (cero descuadres).
- **Tasa de Éxito:** 100% de peticiones atendidas correctamente con código HTTP 200 OK.
- **Resiliencia ante saturación:** El cerrojo asíncrono encola las peticiones de manera ordenada; ante tiempos de espera excesivos, degrada controladamente respondiendo HTTP 503 sin corromper la memoria.

La ejecución se realizó el **2026-11-06** con el comando:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/inventario/test_concurrencia.py -q
```

La prueba terminó en verde (`1 passed`); el valor p95 se capturó con el mismo
flujo HTTP de la prueba, antes de consultar el stock final. El resultado es una
medición de una ejecución local y no una línea base histórica previa al lock.

La entrega anterior reportó 28 ms, pero no conserva una serie de observaciones
ni un artefacto ejecutable que permita reconstruir esa cifra exacta. Se conserva
como referencia histórica, no como línea base verificable. La línea base
cuantitativa antes del lock queda pendiente porque ese estado no está disponible
en el historial evaluado; no se inventa una cifra retrospectiva.

## 6. Resultados crudos y reproducibilidad

| Campo | Resultado conservado |
|---|---|
| Fecha de ejecución histórica | 2026-11-06 |
| Fecha de cinco ejecuciones actuales | 2026-11-15 |
| Commit de la evidencia actual | `a5cd1d8bff1ebac701ba8b682c512929f888a459` |
| Ejecuciones independientes actuales | 5 |
| Solicitudes por ejecución | 20 `POST /inventario/{sku}/salidas` |
| Latencias individuales | Conservadas en el artefacto JSON versionado |
| p95 por ejecución | 29.403, 27.729, 28.000, 33.788 y 29.120 ms |
| Respuestas HTTP | 100/100 con `200` |
| Stock inicial/final por ejecución | 100/80 |
| Umbral | 400 ms |
| Conclusión | Cumple para ESC-01 y aporta evidencia parcial para ESC-04 |

La cifra histórica de 32.891 ms se conserva como resultado reportado del
2026-11-06, no como una serie cruda reconstruida. La serie actual tiene un p95 máximo de 33.788 ms, todavía por debajo del umbral de 400 ms en las cinco
ejecuciones.

## 7. Seguimiento de observaciones de pares

La sección 11 de arc42 debe distinguir lo conocido de lo asumido. La revisión
conservada en el repositorio contiene la siguiente observación:

| Observación | Estado | Evidencia y decisión |
|---|---|---|
| Contrastar explícitamente la medición con el umbral del escenario y hacer visibles sus riesgos | Corregido | Se añadió el p95 de 32.891 ms frente a 400 ms, el margen de 367.109 ms y las deudas de persistencia, autenticación, identidad e idempotencia en [arc42 §11](../arc42/arc42-template-EN.md#11-risks-and-technical-debt-riesgos-y-deuda-técnica). |

No se conserva en el historial revisado un listado separado de otros
señalamientos individuales. Por tanto, no se marcan observaciones adicionales
como corregidas, asumidas o pendientes sin evidencia.

## 8. Conclusión y Consecuencias Arquitectónicas
El experimento valida empíricamente que el diseño de monolito modular con puertos, adaptadores y exclusión mutua por SKU resuelve el reto de consistencia transaccional del MVP con un costo de infraestructura cero (C5). Como deuda técnica conocida (documentada en arc42 §11), este almacenamiento en memoria es transitorio y requerirá persistencia relacional transaccional ante despliegues con múltiples réplicas horizontales.