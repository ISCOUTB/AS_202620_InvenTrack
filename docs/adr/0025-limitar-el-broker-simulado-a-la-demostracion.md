# ADR-0025: Limitar el broker simulado a la demostración en memoria

- **Estado:** Aceptado
- **Fecha:** 2026-11-27
- **Decisores:** Equipo InvenTrack
- **Complementa:** [ADR-0016](0016-integrar-eventos-de-auditoria-en-movimientos.md) para la demo y [ADR-0020](0020-persistir-inventario-y-auditoria-en-sqlite.md) para SQLite.

## Contexto y alternativas

En el perfil durable, una entrada o salida escribía su evento con actor en SQLite y además lo enviaba al simulador del taller. El simulador retenía mensajes, claves y registros de consumo en colecciones que crecían durante la vida del proceso. Esa segunda copia se perdía al reiniciar. El trabajador de correo ya leía sus avisos de SQLite.

Mantener ambos recorridos preservaba los contadores del simulador a costa de ese crecimiento. Incorporar un broker externo habría exigido operar otro servicio y coordinar su entrega con la transacción SQLite. El único consumidor externo actual, SMTP, ya dispone de la cola persistente `correos_stock`.

## Decisión

En la demo, el router sigue publicando al simulador en segundo plano. Con SQLite, guarda la auditoría y el aviso que corresponda dentro de la transacción del movimiento.

## Consecuencias y reversión

Un fallo de persistencia revierte el comando. Repetir una clave exitosa con el mismo actor y los mismos datos reproduce su respuesta. En el perfil SQLite, los contadores del broker permanecen en cero. La auditoría y el estado de la cola se consultan en la base.

Para revertir la decisión, el router volvería a publicar cada evento nuevo en el simulador además de guardarlo en SQLite. Esto volvería a acumular una copia de los eventos en memoria.

## Trazabilidad

El aspecto ASP-04 exige conservar el evento de cada movimiento confirmado. La prueba de Gestión registra una entrada y dos salidas, repite una venta, rechaza otra por falta de stock y exige tres eventos durables y cero publicaciones al simulador. Tras restaurar la copia en otro archivo, comprueba el historial, el cierre y la entrega del aviso pendiente. [Aspecto de auditoría](../aspectos.md#asp-04--mensajeria-asincrona-y-auditoria) · [Flujo C4](../../c4-actual/05-flujos.md) · [Router](../../app/inventario/infrastructure/router.py) · [Prueba durable](../../tests/test_gestion_integrada.py) · [Prueba de la demo](../../tests/inventario/test_inventario.py) · [Commit de implementación](https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/6c031e04df3f8539d8166d609e29830b365eef18).
