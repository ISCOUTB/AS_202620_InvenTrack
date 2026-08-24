# Aspectos de Calidad

Este archivo sigue el modelo de trazabilidad visto en clase:

```
Aspecto → Requisito → C4 → ADR → Código → Pruebas → Evidencia
```

Un **aspecto** no es una capa del sistema ni un módulo — es un corte
vertical, de punta a punta, que se puede recorrer completo: desde la
necesidad que lo justifica hasta la evidencia que demuestra que se
cumplió. La tabla de abajo tiene una fila por aspecto declarado, con las
ocho columnas que exige el curso; cada celda enlaza al artefacto real
cuando existe, o dice explícitamente "Pendiente" cuando no — una celda no
puede quedar con un texto que no lleve a ninguna parte.

Por ahora el equipo ha declarado **un solo aspecto**: Consistencia de
datos. Puede haber más aspectos declarados en semanas futuras si el
equipo decide convertir otro atributo de calidad priorizado (por ejemplo
Disponibilidad o Seguridad, ver el [árbol de utilidad](utility-tree.md))
en su propio corte vertical — en ese momento se agregaría una fila nueva
a esta misma tabla.

## Tabla de trazabilidad

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|---|---|---|---|---|---|---|---|
| ASP-01 | [Consistencia de datos](#asp-01--consistencia-de-datos) | [ESC-01, ESC-02](arc42/arc42-template-EN.md#quality-scenarios) | [C4 de contexto](c4/context.md) — módulo `inventario` | [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md) — define el módulo `inventario` como límite; el mecanismo específico de concurrencia sigue pendiente (ADR-0002) | [`app/inventario/`](../app/inventario/) (esqueleto de módulo, sin lógica de negocio aún) | Pendiente — [`tests/test_health.py`](../tests/test_health.py) existe pero aún no cubre este aspecto | Pendiente |

## ASP-01 — Consistencia de datos

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

### Requisito: escenarios de calidad

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
**pertenecen a este aspecto específico**. Los otros tres (Disponibilidad,
Rendimiento, Seguridad) están documentados igual de completos en el
arc42, pero no tienen fila propia aquí todavía porque no se ha declarado
un aspecto propio para ellos.

### C4: dónde vive este aspecto

El [diagrama de contexto](c4/context.md) muestra que este aspecto vive en
el módulo de registro de movimientos dentro de InvenTrack, expuesto a los
dos actores (Dueño y Empleado) que pueden operar de forma simultánea. En
la estructura de código, corresponde al módulo
[`app/inventario/`](../app/inventario/), definido en el
[ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md)
como parte del Monolito Modular.

### ADR: estilo definido, mecanismo técnico pendiente

El [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md)
ya resuelve dónde vive este aspecto en el código (módulo `inventario`,
con dominio separado de infraestructura vía hexagonal) y fue evaluado
explícitamente contra ESC-01 y ESC-02 en la
[matriz comparativa](matriz-comparativa-estilos.md). Lo que sigue
pendiente es el **mecanismo concreto** para garantizar consistencia en
movimientos concurrentes — ese será el ADR-0002. Las alternativas que el
equipo tiene sobre la mesa para esa segunda decisión:

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
evaluada contra ESC-01 y su medida verificable.

### Código y pruebas (pendiente)

El módulo `app/inventario/` existe como esqueleto (`domain/`,
`application/`, `infrastructure/`, todos vacíos por ahora, según define el
ADR-0001) — todavía no contiene la lógica de negocio ni el mecanismo de
concurrencia. `tests/test_health.py` prueba que la aplicación arranca,
pero no cubre este aspecto todavía; la prueba de concurrencia con 50
transacciones simultáneas (la medida de ESC-01) se agregará junto con el
ADR-0002.

### Estado

- [x] Aspecto identificado y declarado
- [x] Escenarios de calidad definidos (ESC-01, ESC-02)
- [x] Módulo del esqueleto delimitado (`app/inventario/`, vía ADR-0001)
- [ ] Mecanismo técnico de garantía definido (ADR-0002 pendiente)
- [ ] Mecanismo implementado
- [ ] Pruebas de concurrencia realizadas