# ADR-0020: Persistir catálogo, inventario y auditoría en una transacción SQLite

- **Estado:** Aceptado
- **Fecha:** 2026-11-19
- **Decisores:** Equipo InvenTrack
- **Reemplaza:** La decisión de usar memoria de [ADR-0012](0012-mantener-repositorios-en-memoria-en-el-mvp.md), [ADR-0014](0014-estrategia-de-almacenamiento-y-costo-de-reversion.md) y [ADR-0015](0015-completar-decision-de-almacenamiento-y-reversion.md) en el perfil durable. El desarrollo sin base configurada conserva los adaptadores en memoria.
- **Complementa:** [ADR-0016](0016-integrar-eventos-de-auditoria-en-movimientos.md) y [ADR-0017](0017-idempotencia-http-en-comandos-de-inventario.md).

## Contexto y alternativas

El equipo amplía el MVP a datos que deben sobrevivir al reinicio. PostgreSQL permitiría varios nodos escritores, a costa de administrar otro servicio. Los diccionarios del perfil de demostración pierden saldos, claves y auditoría al reiniciar. SQLite sobre un volumen local satisface el alcance de una sola instancia sin dependencia adicional de Python.

## Decisión

Cada módulo conserva sus puertos. Los adaptadores de catálogo e inventario comparten una conexión por petición. Una escritura obtiene una transacción inmediata antes de validar producto o saldo. Stock, historial, resultado por clave y actor, y evento íntegro de auditoría se confirman juntos. Un error provoca rollback. Los reintentos del mismo actor reciben el resultado guardado. El registro de auditoría se puede consultar aun si el consumidor de demostración está inactivo. El broker y su DLQ continúan en memoria. Para entregar eventos a un sistema externo se requerirá un despachador durable con confirmación del consumidor.

La API de backup de SQLite toma una instantánea consistente con WAL activo. La restauración usa una ruta nueva y verifica integridad. El acceso al volumen y a sus copias corresponde a operaciones. Las tablas se crean en la primera ejecución. Una migración futura necesita versionar el esquema. Datos ya perdidos por un reinicio del perfil en memoria son irrecuperables.

## Consecuencias y reversión

Un solo escritor por archivo aumenta la contención con carga alta. Al agotar la espera, la API responde 503. Disk full y pérdida del volumen requieren intervención. Operar una instancia con disco local, copia fuera del host y prueba de recuperación antes de activar datos reales. La reversión operacional consiste en cerrar negocio, detener la instancia, verificar una copia y restaurar en un archivo nuevo. Volver a memoria permite demostraciones locales, pero no recuperar datos de usuarios.

## Trazabilidad

[ESC-01 y ESC-03](../arc42/arc42-template-EN.md#quality-scenarios), [C4 de contenedores](../c4/containers.md), [transacción](../../app/shared/infrastructure/sqlite.py), [inventario y auditoría](../../app/inventario/infrastructure/sqlite_repository.py), [catálogo](../../app/productos/infrastructure/sqlite_repository.py), [respaldo](../../app/shared/infrastructure/respaldo.py), [prueba de recuperación](../../tests/test_perfil_durable.py) y [medición HTTP](../retos/escenarios-2026-11-19.json). Cambio posterior a 95baaf0, pendiente de integración.
