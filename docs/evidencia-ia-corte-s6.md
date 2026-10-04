# Evidencia de una porcion construida con apoyo de IA: S6

Esta evidencia sigue la cadena exigida por el contrato del repositorio:
**aspecto -> requisito -> ADR -> codigo -> prueba -> evidencia de defecto -> medicion**.
La porcion corresponde a la integracion real entre `productos` e `inventario`,
implementada en la semana 6 y registrada en el commit
[`d6f2b190`](https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/d6f2b1905909f89eae41f36e1963a0fc688618e7).

## 1. Aspecto y requisito

La fila aplicable es [ASP-01 - Consistencia de datos](aspectos.md#asp-01--consistencia-de-datos)
en [`docs/aspectos.md`](aspectos.md).

El escenario asociado es **ESC-02**: cuando un producto tiene movimientos de
inventario, no se permite el borrado fisico; se aplica desactivacion logica y
se conserva la trazabilidad.

## 2. Decision del equipo

La decision esta registrada en
[ADR-0003](adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion.md),
que tiene estado **Aceptado** y fecha 2026-09-13. El equipo eligio una llamada
sincrona entre capas de aplicacion, mediada por puertos propios y adaptadores.

Para ESC-02, `productos` conserva el puerto `VerificadorDeMovimientos` y usa
`HistorialMovimientosAdapter` para consultar el caso de uso real
`ConsultarHistorialMovimientos` de `inventario`. No se importa directamente el
dominio ni la infraestructura de otro modulo.

No se modifica el ADR aceptado; esta evidencia lo enlaza y describe su
implementacion.

## 3. Codigo enlazado

- [EliminarProducto](../app/productos/application/eliminar_producto.py)
- [Puerto de movimientos](../app/productos/domain/ports.py)
- [HistorialMovimientosAdapter](../app/productos/infrastructure/historial_movimientos_adapter.py)
- [ConsultarHistorialMovimientos](../app/inventario/application/consultar_movimientos.py)
- [Repositorio real de movimientos](../app/inventario/infrastructure/in_memory_movimiento_repository.py)
- [Composicion de adaptadores](../app/main.py)

El dueño de escritura de `Movimiento` es `app/inventario`, de acuerdo con
[docs/propiedad-datos.md](propiedad-datos.md). `productos` solo consulta el
historial mediante el puerto.

## 4. Pruebas en estado correcto

Las pruebas que cubren la porcion son:

- [test_historial_real.py](../tests/productos/test_historial_real.py): comprueba
  que el adaptador ve un movimiento registrado en el repositorio real de
  `inventario`.
- [test_api_corte_vertical.py](../tests/productos/test_api_corte_vertical.py):
  comprueba que un producto con movimientos se desactiva y no se elimina
  fisicamente.

Comando ejecutado en Windows:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/productos/test_historial_real.py tests/productos/test_api_corte_vertical.py -v
```

Resultado de la linea base:

```text
4 passed, 1 warning in 0.60s
```

La advertencia corresponde a la configuracion futura de `pytest-asyncio`; no
cambia el resultado de las pruebas.

## 5. Prueba que falla ante el defecto

Se introdujo temporalmente este defecto en
`app/productos/infrastructure/historial_movimientos_adapter.py`:

```python
def tiene_movimientos_asociados(self, producto_id: str) -> bool:
    return False
```

El defecto simula que el adaptador ignora el historial real. Sin cambiar las
pruebas, el mismo comando produjo:

```text
2 failed, 2 passed, 1 warning in 1.05s
```

Fallaron concretamente:

```text
test_adaptador_refleja_movimientos_reales_de_inventario
AssertionError: assert False is True

test_corte_vertical_eliminar_producto_con_movimientos_lo_desactiva
assert True is False
```

La primera falla demuestra que el adaptador dejo de leer el movimiento real.
La segunda demuestra el defecto de negocio: el producto con movimientos se
habria eliminado fisicamente.

El cambio se revirtio inmediatamente a:

```python
return self._consultar_historial.tiene_movimientos(producto_id)
```

Al repetir el comando, las 4 pruebas volvieron a pasar. El arbol de trabajo
quedo sin el defecto experimental.

## 6. Medicion del escenario

La medicion reproducible de esta porcion es la cobertura funcional del escenario
ESC-02:

| Indicador | Resultado |
|---|---:|
| Casos de producto sin movimientos | 1/1 correcto |
| Casos de producto con movimientos reales | 1/1 correcto |
| Producto con movimientos eliminado fisicamente | 0 |
| Producto con movimientos desactivado logicamente | 1 |
| Pruebas de la porcion en verde | 4/4 |
| Cumplimiento funcional de ESC-02 | 100 % |

El resultado se obtiene ejecutando las pruebas anteriores; no es una estimacion
manual. La medicion de rendimiento de concurrencia pertenece a ASP-02 y no se
mezcla con este escenario.

## 7. Uso de IA y criterio del equipo

El registro completo esta en [docs/ia.md](ia.md), en la entrada de
**2026-09-13 - Integracion productos-inventario, mapa de contextos y
endurecimiento de seguridad del CI (S6)**.

Para esta porcion:

- **Aceptado:** apoyo de IA para redactar ADR-0003, estructurar los adaptadores,
  documentar el mapa de contextos, registrar la propiedad de datos y describir
  la auditoria de modularidad.
- **Corregido:** la violacion `VIO-01`, donde la verificacion dependia de un
  doble de prueba y no consultaba el historial real de `inventario`.
- **Rechazado:** mantener dependencias directas entre dominios o infraestructura
  de modulos, porque violaba el aislamiento modular y la regla de dueño unico.

La auditoria correspondiente esta en
[auditoria-modularidad.md](auditoria-modularidad.md), donde `VIO-01` documenta
la causa, el riesgo y la correccion mediante puertos de aplicacion y
adaptadores. La propiedad de `Movimiento` y su canal de consulta estan en
[propiedad-datos.md](propiedad-datos.md).
