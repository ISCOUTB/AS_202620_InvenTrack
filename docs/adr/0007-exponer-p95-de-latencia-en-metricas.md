# ADR-0007: Exponer p95 de latencia en las metricas HTTP

- **Estado:** Pendiente
- **Fecha:** 2026-10-04
- **Decisores:** Equipo InvenTrack

## Contexto

El escenario ESC-04 exige observar la latencia de las peticiones y comprobar que
el percentil 95 sea menor o igual a 400 ms. El middleware ya conserva un
historial acotado por metodo y ruta, pero el calculo del p95 estaba embebido en
el endpoint `/metrics` y no tenia una prueba aislada que detectara un indice de
percentil incorrecto.

## Opciones evaluadas

1. Dejar el calculo inline y validarlo solo mediante una prueba HTTP completa.
2. Crear una funcion de dominio para todas las metricas y agregar una
   dependencia de observabilidad externa.
3. Extraer el calculo local a una funcion pequena, conservar el historial acotado
   existente y probar la regla con pytest.

## Decision

Se adopta la opcion 3. La funcion `_p95_latency` usa el rango mas cercano
(`ceil(n * 0.95)`) sobre la lista ordenada y `/metrics` publica el resultado en
la serie `inventrack_http_p95_latency_seconds`. No se agrega una dependencia
nueva ni se cambia el contrato HTTP existente.

## Consecuencias

- ESC-04 tiene una regla de calculo aislada y reproducible.
- El historial continua limitado a 1000 observaciones por ruta.
- La metrica sirve para verificar el umbral operacional, pero no reemplaza una
  medicion de carga; la medicion debe registrar las peticiones y compararlas con
  400 ms.
- Si se requiere p95 distribuido entre procesos, sera necesario otro ADR y una
  solucion de observabilidad externa.

## Trazabilidad

- **Aspecto:** ASP-03, observabilidad de latencia y ESC-04.
- **Codigo:** `app/main.py`, funcion `_p95_latency` y endpoint `/metrics`.
- **Prueba:** `tests/test_metrics.py`.
- **Implementacion:** commit de la entrega S9 que incorpora este ADR, codigo,
  prueba y evidencia.
