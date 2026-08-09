# Aspectos de Calidad

## Aspecto declarado: Consistencia de datos

### Descripción

El sistema debe garantizar que los movimientos de inventario (entradas, salidas y
ajustes) realizados de forma concurrente por distintos usuarios no dejen el inventario en
un estado inconsistente. Casos concretos que este aspecto busca prevenir:

- Dos usuarios registran una salida del mismo producto al mismo tiempo y el stock queda
  descontado solo una vez (o descontado de más).
- Un producto queda con stock negativo por una condición de carrera entre dos
  transacciones simultáneas.
- Un movimiento se registra dos veces por reintentos de red o fallos de sincronización.

### Por qué se eligió este aspecto

En un sistema de inventarios, la confianza en el dato es el valor central del producto.
Un sistema que reporta cifras incorrectas es más peligroso que un registro manual, porque
genera falsa seguridad: el usuario toma decisiones de compra, venta o reposición
basándose en un número que no refleja la realidad. Por eso la consistencia no es un
"extra" técnico, sino el requisito que justifica la existencia misma del sistema frente a
la alternativa manual (Excel).

### Cómo se va a evaluar / demostrar

Se documentará más adelante el mecanismo elegido para garantizar consistencia en
movimientos concurrentes (por ejemplo: transacciones con nivel de aislamiento adecuado,
bloqueos optimistas o pesimistas sobre el registro de stock, o validaciones a nivel de
base de datos que impidan valores negativos). Esta sección se irá actualizando a medida
que el equipo tome esas decisiones de diseño.

### Estado

- [x] Aspecto identificado y declarado
- [ ] Mecanismo técnico de garantía definido
- [ ] Mecanismo implementado
- [ ] Pruebas de concurrencia realizadas