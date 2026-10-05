# Evidencia S9: porción generada y verificada con apoyo de IA

Esta evidencia corrige el hallazgo de semana 9: la entrega S9 debe contener una
porción de código en `app/` y `tests/` introducida en el periodo, no solo documentación de
despliegue. La porción es el cálculo matemático aislado del p95 que alimenta el endpoint `/metrics`.

## 1. Aspecto y requisito

La fila aplicable es [ASP-03 - Observabilidad de latencia](aspectos.md#asp-03--observabilidad-de-latencia).
El escenario es **ESC-04**: las peticiones deben mantener un p95 menor o igual a
400 ms en estado caliente.

## 2. ADR y decisión del equipo

La decisión está en [ADR-0007](adr/0007-exponer-p95-de-latencia-en-metricas.md).
El equipo eligió extraer `_p95_latency` a una función local, mantener el
historial acotado existente (`deque` en memoria) y no agregar una dependencia externa de
observabilidad para respetar la restricción presupuestaria **C5 ($0.00 USD)**.

No se reescribieron ADR aceptados; se añadió uno nuevo que documenta esta porción.

## 3. Código de la porción

- [`app/main.py`](../app/main.py): función `_p95_latency` y endpoint `/metrics`.
- [`tests/test_metrics.py`](../tests/test_metrics.py): prueba del rango más
  cercano para p95, aislando casos atípicos (p100).
- [`docs/adr/0007-exponer-p95-de-latencia-en-metricas.md`](adr/0007-exponer-p95-de-latencia-en-metricas.md): decisión y consecuencias.

Esta porción fue añadida en la corrección de S9 sobre la rama principal, asegurando que existan cambios funcionales medibles, además de los de infraestructura.

## 4. Prueba en verde

Comando ejecutado:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/test_metrics.py -v
```

Resultado esperado y obtenido:

```text
tests/test_metrics.py::test_p95_latency_uses_nearest_rank PASSED
1 passed
```

La prueba usa una simulación robusta de 100 observaciones: 94 rápidas (0.010s), 5 medias (0.050s) y 1 atípica (0.500s). Exige que el $p95$ aísle la anomalía y retorne exactamente 0.050.

## 5. Prueba que falla ante el defecto

Se verificó la robustez de la prueba simulando un defecto de generación de IA, donde el modelo confunde el cálculo del percentil 95 con el valor máximo absoluto (p100).

Se reemplazó temporalmente la implementación correcta:

```python
def _p95_latency(history: list[float]) -> float:
    ordered = sorted(history)
    rank = max(1, math.ceil(len(ordered) * 0.95))
    return ordered[rank - 1]
```

por el calculo defectuoso:

```python
def _p95_latency(history: list[float]) -> float:
    return max(history)
```

Al ejecutar la prueba, el defecto selecciona la anomalía de 500 ms y la prueba falla protegiendo la regla de negocio con el siguiente error:

```text
E       assert 0.5 == 0.05
1 failed
```

La implementación correcta se restauró inmediatamente y la prueba volvió a
pasar. El defecto no permanece en el árbol de trabajo.

## 6. Medición del escenario

La prueba de regla confirma el cálculo matemático, pero la medición de rendimiento debe
compararse contra el umbral de ESC-04. La medición reproducible de esta porción
se registra así:

| Indicador | Umbral / Regla | Resultado | Estado |
|---|---|---|---|
| Observaciones usadas para p95 | Historial acotado por ruta | Hasta 1000 en memoria | Cumple |
| p95 calculado por la prueba | Aísla anomalías (p100) | 50 ms en el caso de prueba | Cumple |
| Latencia operacional ESC-04 | <= 400 ms | 9.066 ms (p95, 20 peticiones reales) | Cumple |
| Detección de defecto (Mutación) | La prueba debe fallar | 0.5 != 0.05 | Cumple |

Se midieron 20 peticiones reales a `GET /health` con
`TestClient` localmente: las 20 respondieron `200`, el p95 fue `9.066 ms` y el máximo
`9.655 ms`. Esta medición en estado caliente contrasta satisfactoriamente con el umbral de
ESC-04 (<= 400 ms). 

## 7. Relación con el uso de IA y Control de Erosión

La entrada de S9 en [`docs/ia.md`](ia.md) registra que la IA apoyó la
extracción de la regla matemática, la robustez de la prueba de 100 elementos y la redacción del ADR-0007. 

**Auditoría de erosión:**
- **Dependencias:** Se rechazó la introducción de herramientas como `prometheus-client` o `numpy` sugeridas por la IA para evitar inflar el `requirements.txt` y violar la restricción C5.
- **Límites de contexto:** Se verificó que el middleware y el cálculo de observabilidad residan estrictamente en el *composition root* (`app/main.py`), sin acoplarse ni invadir los dominios de `inventario` o `productos`.