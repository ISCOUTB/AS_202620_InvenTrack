# Evidencia S9: porcion generada y verificada con apoyo de IA

Esta evidencia corrige el hallazgo de semana 9: la entrega S9 debe contener una
porcion de `app/` y `tests/` introducida en el periodo, no solo documentacion de
despliegue. La porcion es el calculo aislado del p95 que alimenta `/metrics`.

## 1. Aspecto y requisito

La fila aplicable es [ASP-03 - Observabilidad de latencia](aspectos.md#asp-03--observabilidad-de-latencia).
El escenario es **ESC-04**: las peticiones deben mantener un p95 menor o igual a
400 ms en estado caliente.

## 2. ADR y decision del equipo

La decision esta en [ADR-0007](adr/0007-exponer-p95-de-latencia-en-metricas.md).
El equipo eligio extraer `_p95_latency` a una funcion local, mantener el
historial acotado existente y no agregar una dependencia externa de
observabilidad.

No se reescribieron ADR aceptados.

## 3. Codigo de la porcion

- [`app/main.py`](../app/main.py): funcion `_p95_latency` y endpoint `/metrics`.
- [`tests/test_metrics.py`](../tests/test_metrics.py): prueba del rango mas
  cercano para p95.
- [`docs/adr/0007-exponer-p95-de-latencia-en-metricas.md`](adr/0007-exponer-p95-de-latencia-en-metricas.md): decision y consecuencias.

Esta porcion fue añadida en la correccion de S9 sobre la punta que antes solo
contenia cambios de documentacion y despliegue.

## 4. Prueba en verde

Comando:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/test_metrics.py -v
```

Resultado esperado y obtenido:

```text
1 passed
```

La prueba usa duraciones `[0.010, 0.020, 0.030, 0.040]` y exige que el p95 sea
`0.040`.

## 5. Prueba que falla ante el defecto

Se verifico el defecto reemplazando temporalmente el rango correcto:

```python
rank = max(1, math.ceil(len(ordered) * 0.95))
```

por el calculo defectuoso:

```python
rank = max(1, int(len(ordered) * 0.95))
```

Con cuatro observaciones, el defecto selecciona el indice `2` en vez del rango
95 correcto y la prueba falla con:

```text
E       assert 0.03 == 0.04
1 failed
```

La implementacion correcta se restauro inmediatamente y la prueba volvio a
pasar. El defecto no permanece en el arbol de trabajo.

## 6. Medicion del escenario

La prueba de regla confirma el calculo, pero la medicion de rendimiento debe
compararse contra el umbral de ESC-04. La medicion reproducible de esta porcion
se registra asi:

| Indicador | Umbral | Resultado | Estado |
|---|---:|---:|---|
| Observaciones usadas para p95 | Historial acotado por ruta | hasta 1000 | Cumple |
| p95 calculado por la prueba | Rango 95 correcto | 40 ms en el caso de prueba | Cumple |
| Latencia operacional ESC-04 | <= 400 ms | 9.066 ms (p95, 20 peticiones) | Cumple |
| Formula defectuosa detectada | La prueba debe fallar | 0.03 != 0.04 | Cumple |

El caso controlado de la prueba representa duraciones de 10, 20, 30 y 40 ms.
Adicionalmente, se midieron 20 peticiones reales a `GET /health` con
`TestClient`: las 20 respondieron `200`, el p95 fue `9.066 ms` y el maximo
`9.655 ms`. Esta medicion local en estado caliente contrasta el umbral de
ESC-04; la medicion de carga concurrente de inventario de ASP-02 sigue siendo
evidencia independiente y no se presenta como medicion nueva de S9.

## 7. Relacion con el uso de IA

La entrada de S9 en [docs/ia.md](ia.md) debe registrar que la IA apoyo la
extraccion de la regla, la propuesta de la prueba y la redaccion del ADR. La
decision aceptada por el equipo fue conservar una solucion local y sin nuevas
dependencias. Se rechazo introducir un cliente externo de observabilidad porque
no era necesario para el MVP y ampliaba el costo operativo.
