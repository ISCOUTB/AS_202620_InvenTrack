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

### Escenarios de calidad (Semana 2)

Este aspecto se refinó en dos escenarios de calidad medibles, documentados en
[`docs/arc42/arc42-template-EN.md`](arc42/arc42-template-EN.md) (sección Quality
Requirements) y en el [árbol de utilidad](utility-tree.md):

- **ESC-01 — Registro simultáneo de salida del mismo producto** *(prioridad: impacto de
  negocio alto, riesgo técnico alto)*. Dos empleados registran una salida del mismo
  producto al mismo tiempo; el sistema debe serializar las transacciones y aplicar ambos
  descuentos de forma consistente, o rechazar una si el stock resultante sería negativo.
  Medida: 0 casos de stock negativo y 0 casos de doble descuento en 100 % de una prueba
  de concurrencia con 50 transacciones simultáneas.
- **ESC-02 — Eliminar producto con movimientos asociados** *(prioridad: impacto medio,
  riesgo medio)*. Un administrador intenta eliminar un producto con historial de
  movimientos; el sistema debe impedir el borrado físico y permitir solo desactivación
  (borrado lógico), preservando la trazabilidad. Medida: verificado con prueba
  automatizada sobre el 100 % de los casos.

El [diagrama de contexto](c4/context.md) muestra dónde vive este aspecto: en el
módulo de registro de movimientos dentro de InvenTrack, expuesto a los dos actores
(Dueño y Empleado) que pueden operar de forma simultánea.

### Cómo se va a evaluar / demostrar

Se documentará más adelante el mecanismo elegido para garantizar consistencia en
movimientos concurrentes (por ejemplo: transacciones con nivel de aislamiento adecuado,
bloqueos optimistas o pesimistas sobre el registro de stock, o validaciones a nivel de
base de datos que impidan valores negativos). Esa decisión se registrará como ADR en
[`docs/adr/`](adr/) y se enlazará aquí. Esta sección se irá actualizando a medida
que el equipo tome esas decisiones de diseño.

### Estado

- [x] Aspecto identificado y declarado
- [x] Escenarios de calidad definidos (ESC-01, ESC-02)
- [ ] Mecanismo técnico de garantía definido (ADR pendiente)
- [ ] Mecanismo implementado
- [ ] Pruebas de concurrencia realizadas
