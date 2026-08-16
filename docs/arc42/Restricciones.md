# Restricciones

Las restricciones arquitectónicas de este sistema se derivan del problema identificado, del alcance definido para el MVP y del aspecto de calidad prioritario: la consistencia de los datos del inventario. Estas restricciones condicionan las decisiones de diseño y delimitan las características que debe cumplir la solución.

## Consistencia en operaciones concurrentes

El sistema debe garantizar que las operaciones de inventario realizadas simultáneamente por diferentes usuarios no generen inconsistencias en el stock.

En particular, se debe evitar:

* Que dos usuarios registren simultáneamente la salida del mismo producto y el stock sea descontado incorrectamente.
* Que una condición de carrera produzca valores de stock negativos.
* Que una misma operación sea registrada más de una vez debido a reintentos de red o fallos de sincronización.

Esta restricción es prioritaria porque la consistencia de los datos constituye el principal atributo de calidad declarado para InvenTrack. Un inventario incorrecto puede llevar a decisiones equivocadas de compra, venta o reposición.

**Implicación arquitectónica:** las operaciones que modifiquen el inventario deberán ejecutarse de manera atómica y contar con mecanismos de control de concurrencia. El mecanismo específico —por ejemplo, transacciones, bloqueos o validaciones a nivel de base de datos— aún debe ser definido por el equipo.

## Centralización de la información del inventario

La información relacionada con productos, proveedores y movimientos debe mantenerse centralizada para proporcionar una visión consistente del inventario actual.

Esta restricción responde al problema de gestión mediante archivos de Excel y registros manuales, que puede producir descuadres de stock, información desarticulada y dependencia de una única persona.

**Implicación arquitectónica:** debe existir una fuente central de información para el estado actual del inventario y los movimientos registrados.

## Trazabilidad de los movimientos

Cada entrada, salida o ajuste de inventario debe quedar registrado de manera que pueda determinarse quién realizó la operación y cuándo fue realizada.

Esta restricción responde directamente a la falta de trazabilidad identificada en el problema y forma parte del alcance funcional del MVP.
**Implicación arquitectónica:** los movimientos de inventario deberán conservar información suficiente para identificar al usuario responsable y el momento de la operación.

## Control de acceso mediante usuarios

El sistema debe contemplar usuarios identificables para controlar las operaciones realizadas dentro de InvenTrack.

El control de usuarios forma parte de la solución propuesta y está incluido explícitamente dentro del MVP.
**Implicación arquitectónica:** las operaciones relevantes del sistema deberán estar asociadas a un usuario autenticado.

## Alcance limitado del MVP

La arquitectura de la primera versión debe centrarse en las funcionalidades definidas para el MVP:

* Gestión de productos.
* Gestión de proveedores.
* Registro de entradas y salidas.
* Consulta del inventario actual.
* Gestión de usuarios.
* Historial de movimientos.
* Alertas de stock bajo.

La predicción de demanda mediante modelos históricos queda fuera del alcance de esta versión y se plantea como una posible extensión futura, condicionada a disponer de suficiente información histórica.

**Implicación arquitectónica:** la solución no debe introducir dependencias ni componentes específicos para predicción de demanda en el MVP, aunque la arquitectura debería evitar impedir su incorporación futura.

## Contexto de usuarios objetivo

La solución está dirigida principalmente a dueños y empleados de pequeñas y medianas empresas que actualmente gestionan sus inventarios mediante procesos manuales o herramientas desarticuladas.

**Implicación arquitectónica:** la solución debe mantener una complejidad adecuada para el contexto del MVP y priorizar la centralización, confiabilidad y trazabilidad de las operaciones de inventario.
