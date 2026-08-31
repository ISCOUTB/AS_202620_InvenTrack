# Aspectos de Calidad

Este archivo sigue el modelo de trazabilidad visto en clase:

```
Aspecto → Requisito → C4 → ADR → Código → Pruebas → Evidencia
```

Un **aspecto** no es una capa del sistema ni un módulo — es un corte vertical, de punta a punta, que se puede recorrer completo: desde la necesidad que lo justifica hasta la evidencia que demuestra que se cumplió. La tabla de abajo tiene una fila por aspecto declarado, con las ocho columnas que exige el curso; cada celda enlaza al artefacto real.

Por ahora el equipo ha declarado **un solo aspecto**: Consistencia de datos. Puede haber más aspectos declarados en semanas futuras si el equipo decide convertir otro atributo de calidad priorizado en su propio corte vertical.

---

## Tabla de trazabilidad

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|---|---|---|---|---|---|---|---|
| ASP-01 | [Consistencia de datos](#asp-01--consistencia-de-datos) | [ESC-01, ESC-02](arc42/arc42-template-EN.md#quality-scenarios) | [C4 Nivel 2](c4/containers.md) — módulo `productos` y backend | [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md) — Monolito Modular con Hexagonal por Módulo | [`app/productos/`](../app/productos/) — Corte vertical funcional (Dominio, Aplicación e Infraestructura) | [`tests/productos/test_api_corte_vertical.py`](../tests/productos/test_api_corte_vertical.py) | Prueba de corte vertical (API + Hexagonal) en verde en la suite de pruebas automatizada |

---

## ASP-01 — Consistencia de datos

### Descripción

El sistema debe garantizar que las operaciones sobre los productos y movimientos de inventario realizados de forma concurrente o condicional por distintos usuarios no dejen el dominio en un estado inconsistente. Casos concretos que este aspecto busca prevenir:

- Un producto con historial de movimientos es eliminado físicamente de la base de datos, perdiendo la trazabilidad de transacciones pasadas.
- Dos usuarios registran una salida del mismo producto al mismo tiempo y el stock queda descontado solo una vez (o descontado de más).
- Un producto queda con stock negativo por una condición de carrera entre dos transacciones simultáneas.

---

### Por qué se eligió este aspecto

En un sistema de inventarios, la confianza en el dato es el valor central del producto. Un sistema que reporta cifras incorrectas o pierde el historial transaccional genera falsa seguridad. Por eso la consistencia no es un "extra" técnico, sino el requisito principal que justifica la existencia misma del sistema frente a la alternativa manual (Excel).

---

### Requisito: escenarios de calidad

Este aspecto se refinó en dos escenarios de calidad medibles, documentados en [`docs/arc42/arc42-template-EN.md`](arc42/arc42-template-EN.md) y en el [árbol de utilidad](utility-tree.md):

- **ESC-01 — Registro simultáneo de salida del mismo producto** *(prioridad: alta)*. Dos empleados registran una salida del mismo producto al mismo tiempo; el sistema debe serializar las transacciones y aplicar ambos descuentos de forma consistente, o rechazar una si el stock resultante sería negativo.
- **ESC-02 — Eliminar producto con movimientos asociados** *(prioridad: media)*. Un administrador intenta eliminar un producto con historial de movimientos; el sistema debe impedir el borrado físico y permitir solo desactivación (borrado lógico), preservando la trazabilidad. Medida: verificado con prueba automatizada sobre el 100 % de los casos.

---

### C4: dónde vive este aspecto

El [diagrama de contenedores (C4 Nivel 2)](c4/containers.md) y el [diagrama de contexto (C4 Nivel 1)](c4/context.md) muestran que este aspecto vive en la capa de Backend (`API Backend (Monolito Modular)`), la cual expone las reglas de negocio hacia la interfaz. En la estructura del código, se implementó como el primer corte vertical en el módulo [`app/productos/`](../app/productos/), desacoplado mediante puertos y adaptadores según el [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md).

---

### ADR: decisiones aplicadas

El [ADR-0001](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md) resuelve la arquitectura interna del código, garantizando que el dominio esté protegido de dependencias externas:

- **Casos de uso aislados:** `CrearProducto` y `EliminarProducto` coordinan las reglas del sistema.
- **Borrado lógico vs. borrado físico:** La regla de negocio valida si existen movimientos asociados antes de permitir la eliminación física o forzar la desactivación (`ESC-02`).

---

### Código y pruebas (Corte Vertical Implementado)

El módulo [`app/productos/`](../app/productos/) contiene el corte vertical funcional completo:
- **Dominio y Puertos:** `app/productos/domain/` (`producto.py`, `ports.py`, `exceptions.py`).
- **Aplicación:** `app/productos/application/` (`crear_producto.py`, `eliminar_producto.py`).
- **Infraestructura y REST API:** `app/productos/infrastructure/` (`router.py`, `in_memory_repository.py`).

El aspecto está cubierto y validado mediante la suite de pruebas automatizadas:
- **Integración de Corte Vertical (E2E):** [`tests/productos/test_api_corte_vertical.py`](../tests/productos/test_api_corte_vertical.py)
- **Pruebas de Unidad de Dominio:** [`tests/productos/test_eliminar_producto.py`](../tests/productos/test_eliminar_producto.py)

---

### Estado

- [x] Aspecto identificado y declarado
- [x] Escenarios de calidad definidos (ESC-01, ESC-02)
- [x] Diagrama C4 Nivel 2 delimitado y vinculado
- [x] Módulo del corte vertical implementado (`app/productos/`)
- [x] Reglas de consistencia (borrado lógico/físico ESC-02) implementadas
- [x] Pruebas de integración E2E del corte vertical en verde