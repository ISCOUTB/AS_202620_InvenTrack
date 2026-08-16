# Ficha del Problema

**Proyecto:** InvenTrack — Sistema Inteligente de Inventarios
**Curso:** Arquitectura de Software — AS_202620
**Repositorio:** AS_202620_InvenTrack (organización ISCOUTB)

---

## 1. Problema

Las pequeñas y medianas empresas en Cartagena (tiendas, distribuidoras, minimercados,
ferreterías) gestionan su inventario principalmente mediante Excel o registros manuales
en papel. Esta práctica genera consecuencias operativas y económicas concretas:

- **Descuadres de stock**: no hay certeza sobre la cantidad real disponible frente a lo
  registrado.
- **Quiebres de stock no detectados a tiempo**: el faltante de un producto se descubre
  solo cuando el cliente lo pide, perdiendo la venta.
- **Compras mal planificadas**: al no existir datos históricos accesibles, se compra por
  intuición, generando sobre-stock e inmovilizando capital.
- **Falta de trazabilidad**: no queda registro claro de quién realizó cada movimiento de
  inventario, ni cuándo ni por qué.
- **Dependencia de una sola persona**: el conocimiento del inventario suele estar
  concentrado en el dueño o en un archivo que solo él comprende, generando un punto único
  de fallo operativo.

## 2. Solución propuesta

Un sistema de gestión de inventarios que centraliza productos, proveedores, entradas y
salidas de mercancía, con control de usuarios y trazabilidad completa de cada movimiento,
además de alertas automáticas cuando el stock de un producto baja de un umbral crítico.

## 3. Alcance (MVP de esta entrega)

- Gestión de productos
- Gestión de proveedores
- Registro de entradas y salidas
- Consulta de inventario actual
- Gestión de usuarios
- Historial de movimientos (trazabilidad)
- Alertas de stock bajo

**Fuera de alcance por ahora:** predicción de demanda mediante modelos históricos. Se deja
como extensión futura, condicionada a contar con suficiente volumen de datos históricos,
sin comprometer la base arquitectónica definida en esta entrega.

## 4. Aspecto de calidad declarado

**Consistencia de datos.** El sistema debe garantizar que los movimientos de inventario
(entradas, salidas, ajustes) registrados por distintos usuarios de forma simultánea no
generen datos inconsistentes (por ejemplo, stock negativo o doble descuento del mismo
movimiento). Un inventario que reporta cifras incorrectas es peor que uno manual, porque
genera falsa confianza en la toma de decisiones.

Ver detalle de justificación y decisiones asociadas en [`docs/aspectos.md`](aspectos.md).

## 5. Usuarios objetivo

Dueños y empleados de pequeñas y medianas empresas locales que actualmente no cuentan con
un sistema digital de inventario, o que lo manejan de forma manual/desarticulada.
