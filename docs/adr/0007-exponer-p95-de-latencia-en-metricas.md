# ADR-0007: Exponer p95 de latencia en las métricas HTTP

- **Estado:** Aceptado
- **Fecha:** 2026-10-04
- **Decisores:** Equipo InvenTrack

## Contexto

El escenario ESC-04 exige observar la latencia de las peticiones y comprobar que
el percentil 95 ($p95$) sea menor o igual a 400 ms. El middleware ya conserva un
historial acotado por método y ruta, pero el cálculo del $p95$ estaba embebido en
el endpoint `/metrics` y no tenía una prueba aislada que detectara un índice de
percentil incorrecto, dificultando la trazabilidad del aspecto (ASP-03).

## Opciones evaluadas

1. **Dejar el cálculo inline** y validarlo solo mediante una prueba HTTP completa (difícil de aislar para fallos matemáticos).
2. **Agregar una dependencia de observabilidad externa** (ej. Prometheus Client completo o Datadog) para manejar todas las métricas.
3. **Extraer el cálculo local a una función pequeña**, conservar el historial acotado
   existente y probar la regla matemáticamente con `pytest`.

## Decisión

Se adopta la **opción 3**. La función `_p95_latency` usa el índice más cercano
(`ceil(n * 0.95)`) sobre la lista ordenada de latencias y el endpoint `/metrics` publica el resultado en
la serie `inventrack_http_p95_latency_seconds`. 

**Justificación basada en restricciones:** Se descarta la opción 2 para respetar estrictamente la restricción **C5 (Costo cero de infraestructura y herramientas)** y evitar dependencias de terceros innecesarias, manteniendo la API autocontenida y ligera.

## Consecuencias

- ESC-04 tiene una regla de cálculo aislada y reproducible matemáticamente.
- El historial continúa limitado a 1000 observaciones por ruta en memoria para no degradar el rendimiento.
- La métrica sirve para verificar el umbral operacional, pero no reemplaza una
  medición de carga; la medición externa debe registrar las peticiones y compararlas con
  el límite de 400 ms.
- Si en un futuro se requiere $p95$ distribuido entre múltiples procesos (escalado horizontal), será necesario otro ADR y una
  solución de observabilidad externa que agregue las métricas.

## Trazabilidad

- **Aspecto:** ASP-03, observabilidad de latencia y ESC-04.
- **Código:** `app/main.py`, función `_p95_latency` y endpoint `/metrics`.
- **Prueba:** `tests/test_metrics.py`.
- **Implementación:** commit de la entrega S9 que incorpora este ADR, código,
  prueba y evidencia.