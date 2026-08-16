# Aspectos de Calidad

## Qué es este documento

Este archivo sigue el modelo de trazabilidad visto en clase:

```
Aspecto → Requisito → C4 → ADR → Código → Pruebas → Evidencia
```

Un **aspecto** no es una capa del sistema ni un módulo — es un corte
vertical, de punta a punta, que se puede recorrer completo: desde la
necesidad que lo justifica hasta la evidencia que demuestra que se
cumplió. Por eso cada fila de este documento va acumulando enlaces a
medida que avanza el curso: primero el requisito y los escenarios que lo
refinan, después el diagrama C4 donde vive, después el ADR con la decisión
técnica, después el código y las pruebas, y al final la evidencia (por
ejemplo, un run de CI).

Por ahora el equipo ha declarado **un solo aspecto**: Consistencia de
datos. Puede haber más aspectos declarados en semanas futuras si el
equipo decide convertir otro atributo de calidad priorizado (por ejemplo
Disponibilidad o Seguridad, ver el árbol de utilidad) en su propio corte
vertical — en ese momento se agregaría una sección nueva a este mismo
documento, con la misma estructura que la de abajo.

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

Estos tres casos no son hipotéticos ni exagerados: son exactamente el
tipo de descuadre que hoy sufren las PYMEs con Excel, según describe la
ficha del problema — solo que en un sistema digital compartido por varios
usuarios simultáneos, el riesgo de que ocurran aumenta, no disminuye,
si no se diseña explícitamente para evitarlos.

### Por qué se eligió este aspecto

En un sistema de inventarios, la confianza en el dato es el valor central del producto.
Un sistema que reporta cifras incorrectas es más peligroso que un registro manual, porque
genera falsa seguridad: el usuario toma decisiones de compra, venta o reposición
basándose en un número que no refleja la realidad. Por eso la consistencia no es un
"extra" técnico, sino el requisito que justifica la existencia misma del sistema frente a
la alternativa manual (Excel).

Dicho de otra forma: si InvenTrack resolviera todo lo demás (interfaz
bonita, reportes, alertas) pero fallara en esto, sería peor que no tener
sistema, porque el dueño dejaría de verificar manualmente lo que el
sistema ya le está diciendo (falsamente) que es correcto. Ese es también
el motivo por el que este aspecto tiene la prioridad más alta de todo el
árbol de utilidad — impacto de negocio alto y riesgo técnico alto en su
escenario principal (ESC-01).

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

**Por qué solo estos dos y no los cinco escenarios de la arc42:** el
arc42 documenta cinco escenarios en total (ESC-01 a ESC-05), cubriendo
distintos atributos de calidad priorizados. Aquí solo se enlazan los que
**pertenecen a este aspecto específico** — es decir, los que refinan
Consistencia de datos. Los otros tres (Disponibilidad, Rendimiento,
Seguridad) están documentados igual de completos en el arc42, pero no
tienen fila propia aquí todavía porque no se ha declarado un aspecto
propio para ellos.

El [diagrama de contexto](c4/context.md) muestra dónde vive este aspecto: en el
módulo de registro de movimientos dentro de InvenTrack, expuesto a los dos actores
(Dueño y Empleado) que pueden operar de forma simultánea.

### Cómo se va a evaluar / demostrar

Se documentará más adelante el mecanismo elegido para garantizar consistencia en
movimientos concurrentes. Las alternativas que el equipo tiene sobre la mesa, y que se
convertirán en un ADR cuando se elija una:

- **Transacciones con nivel de aislamiento adecuado** (ej. `SERIALIZABLE` o
  `REPEATABLE READ` según el motor de base de datos), dejando que la base de datos
  resuelva la concurrencia.
- **Bloqueo pesimista** sobre el registro de stock del producto mientras dura la
  transacción, evitando que dos escrituras se crucen.
- **Bloqueo optimista** con un campo de versión, rechazando la escritura si el stock
  cambió entre que se leyó y que se intentó actualizar.
- **Validaciones a nivel de base de datos** (ej. un `CHECK constraint` que impida
  guardar un stock negativo), como última línea de defensa independientemente de la
  lógica de aplicación.

Cualquiera de estas opciones implica un trade-off distinto con Rendimiento
(ver la sección "Trade-offs y tensiones identificadas" del arc42), así que
la elección no se hará solo por facilidad de implementación, sino
evaluada contra ESC-01 y su medida verificable. Esa decisión se
registrará como ADR en [`docs/adr/`](adr/) y se enlazará aquí. Esta
sección se irá actualizando a medida que el equipo tome esas decisiones
de diseño.

### Estado

- [x] Aspecto identificado y declarado
- [x] Escenarios de calidad definidos (ESC-01, ESC-02)
- [ ] Mecanismo técnico de garantía definido (ADR pendiente)
- [ ] Mecanismo implementado
- [ ] Pruebas de concurrencia realizadas
