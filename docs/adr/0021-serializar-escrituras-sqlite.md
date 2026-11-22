# ADR-0021: Serializar las escrituras de la instancia SQLite

- **Estado:** Propuesto
- **Fecha:** 2026-11-22
- **Decisores:** Equipo InvenTrack
- **Complementa:** [ADR-0020](0020-persistir-inventario-y-auditoria-en-sqlite.md)

## Contexto y alternativas

En la revisión publicada `522af50`, veinte ventas concurrentes sobre un mismo SKU dieron p95 de 341,296, 771,660 y 388,914 ms. El límite del reto es 400 ms. Cada petición abría su propia conexión y competía por el único escritor SQLite. Una cola local redujo el peor p95 a 412,771 ms en su ensayo. Mantener abierto el WAL con una conexión auxiliar todavía dejó una corrida en 470,009 ms. Cada ensayo conservó el saldo esperado. [Datos iniciales](../retos/comparacion-s10-s16.json) · [cola local](../retos/comparacion-s16-cola.json) · [conexión auxiliar](../retos/comparacion-s16-wal.json).

## Decisión

Durante la vida de la API, las escrituras de su bucle de eventos comparten una conexión por turnos. Cada petición inicia `BEGIN IMMEDIATE`, confirma solo al obtener una respuesta exitosa y revierte cualquier transacción pendiente antes de liberar el turno. Las lecturas usan conexiones independientes. La espera por el turno y por un escritor externo comparte un presupuesto de cinco segundos. Al agotarlo, la API responde `503` con `Retry-After: 1`. La instancia cierra la conexión al terminar. SQLite sigue arbitrando entre procesos.

## Consecuencias y reversión

Las tres corridas de la implementación dieron p95 de 98,660, 98,089 y 102,243 ms con 20 ventas confirmadas y saldo 80 en cada una. La mediana cayó de 388,914 a 98,660 ms en el ensayo local. Se conserva la política de sincronización de SQLite. El volumen, su capacidad de escritura y la copia fuera del host siguen condicionando el rendimiento y la recuperación. Para revertir la implementación puede desplegarse la revisión anterior sobre el mismo esquema con el servicio detenido.

## Trazabilidad

[ASP-02](../aspectos.md#asp-02--control-de-concurrencia-e-inventario-reto-corte-1) · [C4 componentes](../c4/components.md) · [ciclo de vida](../../app/main.py) · [transacción y turno](../../app/shared/infrastructure/sqlite.py) · [prueba de espera, lectura y recuperación](../../tests/test_perfil_durable.py) · [comparación reproducible](../../scripts/comparar_concurrencia.py) · [muestras y huella del código candidato](../retos/comparacion-s16-final.json). La revisión base publicada es [522af50](https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/522af50484dffddd2cb59bee9218ad0d66d40882).
