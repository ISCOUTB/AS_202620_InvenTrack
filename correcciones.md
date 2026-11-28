# Índice Trazable de Correcciones — InvenTrack

Este documento consolida los hallazgos reportados en las evaluaciones automáticas/docentes (S1 a S10), la contrastación de evidencia con la fecha de cierre de cada commit y la trazabilidad de sus correcciones.

---

## 1. Criterios de Auditoría y Verificación de Feedback

> **Criterio Utilizado:** Se evalúa el estado del repositorio según el hash calificado en cada fecha de cierre. Las discrepancias encontradas entre la revisión automática y los artefactos reales se documentan a continuación para garantizar la trazabilidad del Reto Corte 1.

---

## 2. Matriz Trazable de Hallazgos y Correcciones

| ID Hallazgo | Entrega Orig. | Descripción del Hallazgo / Observación | Análisis / Acción Correctiva Aplicada | Ruta del Artefacto / Commit / Run | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **HAL-01** | S1 / S2 | Formato de aspectos de calidad en prosa y columnas incompletas. | Reestructurado a la tabla de 8 columnas navegable (`ID -> Aspecto -> Requisito -> C4 -> ADR -> Código -> Pruebas -> Evidencia`). | [`docs/aspectos.md`](./docs/aspectos.md) | **Corregido** |
| **HAL-02** | S3 | ADR-0001 en estado propuesto. | Ratificado ADR-0001 como **Aceptado** con justificación explícita de la arquitectura de monolito modular. | [`docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md`](./docs/adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md) | **Corregido** |
| **HAL-03** | S4 | Reporte de secciones §4, §5, §6 y §9 de arc42 como no realizadas. | **Aclaración / Discrepancia:** Las secciones sí existían en `arc42-template-EN.md` previo al cierre. Se unificó toda la documentación bajo la ruta estándar de arc42. | [`docs/arc42/`](./docs/arc42/) | **Corregido** |
| **HAL-04** | S4 | Observación sobre C4 Nivel 2 (Frontend y BD no implementados). | **Aclaración:** C4 Nivel 2 documentaba la arquitectura objetivo, marcando explícitamente contenedores como "Por definir". Se refinó para mostrar el estado implementado actual. | [`docs/c4/containers.md`](./docs/c4/containers.md) | **Corregido** |
| **HAL-05** | S5 | Formato de `correcciones.md` redactado en prosa sin matriz estructurada. | Transformado en este índice trazable formal de 6 columnas exigido por la rúbrica. | [`correcciones.md`](./correcciones.md) | **Corregido** |
| **HAL-06** | S6 | Ausencia de mapa de contextos y definición de propiedad de datos. | Creados `context-map.md` y `propiedad-datos.md` delimitando Single Ownership y canales entre módulos. | [`docs/context-map.md`](./docs/context-map.md), [`docs/propiedad-datos.md`](./docs/propiedad-datos.md) | **Corregido** |
| **HAL-07** | S6 | Violación de fronteras de dominio en verificación de movimientos (`in_memory_verificador_movimientos.py`). | Resuelto mediante la implementación de puertos de aplicación e inversión de dependencias cruzada (`ADR-0003`). Documentado en auditoría. | [`docs/adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion`](./docs/adr/0003-integracion-productos-inventario-via-puertos-de-aplicacion.md), [`docs/auditoria-modularidad.md`](./docs/auditoria-modularidad.md) | **Corregido** |
| **HAL-08** | S6 | C4 Nivel 3 (Componentes) marcado como pendiente. | Diseñado e integrado el diagrama de componentes internos de la API Backend en Mermaid. | [`docs/c4/components.md`](./docs/c4/components.md) | **Corregido** |
| **HAL-09** | S9 / S10 | La medición de p95 ejercitaba `/health` y no el flujo de negocio declarado; la línea base anterior no era reproducible. | La prueba de concurrencia mide 20 `POST /inventario/{sku}/salidas` reales, calcula p95 y exige `<= 400 ms`. La cifra histórica de 28 ms se conserva solo como referencia no reproducible; no se inventa una línea base ausente. | [`tests/inventario/test_concurrencia.py`](./tests/inventario/test_concurrencia.py), [`docs/retos/corte-2-experimento.md`](./docs/retos/corte-2-experimento.md), [`docs/evidencia-ia-corte-s9.md`](./docs/evidencia-ia-corte-s9.md) | **Flujo de medición corregido. Línea base previa al bloqueo sin evidencia reproducible.** Las [mediciones comparables de S10 y S16](docs/verificacion-final.md#concurrencia-y-recuperación) corresponden a revisiones posteriores. |
| **HAL-10** | S10 | Cantidades `0` o negativas podían alcanzar el dominio y producir un error no contractual. | Validación `cantidad > 0` en el esquema HTTP, contrato OpenAPI actualizado y pruebas negativas para entradas y salidas. | [`app/inventario/infrastructure/router.py`](./app/inventario/infrastructure/router.py), [`contracts/openapi/v1.json`](./contracts/openapi/v1.json), [`tests/inventario/test_inventario.py`](./tests/inventario/test_inventario.py) | **Corregido** |
| **HAL-11** | S12 / S15 | Observación sobre modificaciones post-creación en ADR-0012 y ADR-0016. | **Aclaración factual:** Los commits `ab80c28` (ADR-0012) y `1269ffb` (ADR-0016) corresponden a la misma jornada de trabajo del 25/octubre para ratificar estado ("Pendiente" a "Aceptado") y detallar observabilidad/deduplicación, sin introducir divergencia o revocación de decisiones arquitectónicas previas. | [`docs/adr/0012-mantener-repositorios-en-memoria-en-el-mvp.md`](docs/adr/0012-mantener-repositorios-en-memoria-en-el-mvp.md), [`docs/adr/0016-integrar-eventos-de-auditoria-en-movimientos.md`](docs/adr/0016-integrar-eventos-de-auditoria-en-movimientos.md) | **Aclarado** |

## Seguimiento posterior a S15

| Hallazgo | Cambio | Evidencia |
|---|---|---|
| S13 · Frontera operativa sin decisión propia | ADR-0018 ratifica el token operativo y ADR-0019 formaliza identidad por usuario. | [ADR-0018](docs/adr/0018-restringir-superficies-internas-en-produccion.md), [ADR-0019](docs/adr/0019-autenticar-usuarios-y-autorizar-por-rol.md) |
| S14 · Carga distinta a §10 | Se conservó el reto anterior y se midieron ambos escenarios literales. | [Ensayo y muestras](docs/verificacion-final.md) |
| Final · Recuperación, actor y gate público | Perfil SQLite con restauración e identidad. Resultados de Sonar por revisión y disponibilidad remota registrados por separado. | [ADR-0020](docs/adr/0020-persistir-inventario-y-auditoria-en-sqlite.md), [verificación](docs/verificacion-final.md) |
| S16 · Una corrida de 20 ventas en SQLite superaba los 400 ms | Serializar las escrituras de la instancia y reutilizar la conexión. Las tres corridas del candidato terminaron con saldo 80 y p95 entre 98,089 y 102,243 ms. | [ADR-0021](docs/adr/0021-serializar-escrituras-sqlite.md), [comparación con S10 y muestras](docs/verificacion-final.md#concurrencia-y-recuperación) |

## Retroalimentación del cierre

La referencia de partida es el commit `51f353704cabdd0100c082d6af3912d18dc83795` de `main`. El equipo indicó que el formulario del jurado no fue compartido. La lista de recomendaciones de los pares de S14 y el número total de recomendaciones recibidas siguen sin confirmar. Las observaciones técnicas públicas y la solicitud del equipo tienen su propio origen en la tabla.

| Recomendación | Origen | Decisión | Justificación o resultado | Cambio y evidencia |
|---|---|---|---|---|
| Determinar qué colores y estilos cambian con el tema | [José · PR 15](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15#discussion_r4661649344) | Aceptada | La pantalla de acceso ahora lee la paleta bajo el `MaterialApp`. Una prueba cambia de tema y compara el color del título. | [061ff1e][cliente] |
| Probar la selección de cada pestaña | [José · PR 15](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15#discussion_r4661662981) | Aceptada | La prueba toca Productos, Inventario e Inicio y comprueba la selección de la barra y la vista visible. | [061ff1e][cliente] |
| Cubrir la salida de sesión con y sin callback | [José · PR 15](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15#discussion_r4661668079) | Aceptada | La demo oculta el control. Al proporcionar la acción, la prueba pulsa «Cerrar sesión» y comprueba una invocación. | [061ff1e][cliente] |
| Reutilizar los estilos de título de Inicio | [José · PR 16](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/16#discussion_r4661695362) | Aceptada | Cuatro títulos comparten el peso y el color del tema. Cada uno conserva su tamaño y espaciado. | [061ff1e][cliente] |
| Revisar el contraste de los acentos de marca | [José · PR 16](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/16#discussion_r4661697081) | Aceptada | Inicio adapta los verdes y el aviso al tema. En claro y oscuro la prueba exige contraste ≥ 4,5 para estos tres acentos sobre sus fondos tintados y para la etiqueta del botón de acceso. | [061ff1e][cliente] |
| Probar el registro de las dos paletas | [José · PR 16](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/16#discussion_r4661717186) | Aceptada | La prueba inspecciona las dos extensiones de `MaterialApp` y lee el título ya renderizado al alternar el tema. | [061ff1e][cliente] |
| Unificar el nombre del getter de sombra | [José · PR 16](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/16#discussion_r4661719984) | Aceptada | `SurfacePanel` usa `context.shadow`, como el campo de la paleta. | [061ff1e][cliente] |
| Guardar el tema entre arranques o declarar su alcance | [José · PR 16](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/16#discussion_r4661722873) | Aceptada | Se documentó la opción de sesión. En un arranque nuevo vuelve el modo del sistema. La prueba restaura el valor anterior al terminar. | [061ff1e][cliente] |
| Explicar el destino del cliente | Solicitud del equipo · 27/11 | Aceptada | README, guía del cliente, C4 y arc42 identifican Android como plataforma final y Windows como entorno exclusivo de pruebas. | [061ff1e][cliente] |
| Distinguir mensajería de demo y auditoría durable | [Revisión técnica, C4][s16] | Aceptada | El almacenamiento durable confirma el evento con el movimiento. El simulador dejó de duplicarlo en RAM. El verificador de enlaces incluye las vistas C4 actuales. | [6c031e0][backend] · [061ff1e][cliente] · [ADR-0025](docs/adr/0025-limitar-el-broker-simulado-a-la-demostracion.md) |
| Repetir inventario, errores, cierre, copia y restauración sobre código identificado | [Corte, C1/C2][corte] y [S16][s16] | Aceptada | Se ejecutó el candidato original y el cambio posterior en bases desechables. En tres corridas por SHA, 50 ventas sobre 40 unidades terminaron con saldo cero. La prueba ampliada recupera desde copia el historial, el corte y el aviso. | [6c031e0][backend] · [061ff1e][cliente] · [Resultados][ensayos] |
| Relacionar la demo institucional con el SHA servido y medir recuperación pública | [Corte, publicación][corte] y [S16, despliegue][s16] | Aplazada | La sonda expone salud. Para demostrar la versión y la recuperación completa hacen falta acceso al despliegue activo, cuenta de ensayo y una restauración acordada en infraestructura institucional con respaldo externo. | [Sondas y alcance][ensayos] |
| Contrastar el inventario completo de Sonar y el historial de credenciales | [Corte, C3][corte] y [S16, transversal][s16] | Aceptada | Se identificaron el análisis del SHA y los inventarios públicos por rama. Se revisaron los objetos Git alcanzables con patrones específicos. El informe conserva el alcance de cada comprobación. | [061ff1e][cliente] · [Consultas y resultados][ensayos] |
| Consolidar registro de IA y evidencia de revisión humana | [S16, colaboración y registro de IA][s16] | Aceptada | La bitácora enlaza versiones de los cuatro meses. Los ocho hilos anteriores permiten comprobar el contenido técnico y su autor. | [061ff1e][cliente] · [Bitácora](docs/ia.md) |
| Verificar alcance, asignación del desafío y contribución individual | [S16, rúbrica][s16] y [corte, C1/C5][corte] | Aplazada | La conciliación tiene pruebas, pero la asignación y el alcance acordado requieren la consigna del aula. La planilla conserva una atribución provisional. La valoración de la defensa corresponde al docente. | [Prueba del desafío](tests/inventario/test_conciliacion_turno.py) · [Planilla del equipo](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/planilla.md) |

Las 15 filas tienen una decisión: 13 aceptadas y dos aplazadas. Ocho proceden de hilos de revisión interna de los PR 15 y 16. Las pruebas modificadas comprueban [el turno restaurado y la auditoría durable](tests/test_gestion_integrada.py) y [la navegación, la sesión y los temas en Flutter](frontend/test/widget_test.dart).

Los enlaces a los commits de trabajo identifican objetos del clon local. Mientras se mantengan locales se consultan con `git show 6c031e0` y `git show 061ff1e`. El historial posterior al candidato se obtiene con `git log --oneline 51f3537..main`. El último CI público verificado pertenece a `51f3537`. Para acreditar la ausencia de regresiones en la entrega publicada se necesita el run verde del SHA que quede en `main` antes del cierre de SAVIO. [Run de la referencia original](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/45112590983).

### Retrospectiva del trabajo

Estas cuatro lecciones se deducen de aportes identificables. Cada integrante tiene pendiente confirmar o corregir la que se vincula con su trabajo.

| Trabajo de referencia | Qué funcionó | Qué quedó corto | Qué cambiar en la próxima iteración |
|---|---|---|---|
| Félix Taborda · [persistencia SQLite](https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/df16ecb) | Restaurar en otro proceso permitió verificar saldo e idempotencia. | El cronómetro arrancó con el respaldo ya descargado. | Medir desde la pérdida del host hasta la primera lectura autenticada en la instancia repuesta y comparar el último movimiento con la hora del respaldo. |
| José Vargas · [simulador](https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/5507934) | Las pruebas de reintento y DLQ hicieron repetibles los fallos de consumo. | La integración durable conservaba una segunda copia de cada evento en RAM. | En cada perfil, probar cuántos eventos se guardan y qué consumidor debe recibirlos. |
| Esteban Peluffo · [controles de acceso](https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/e12e765) | Las sondas anónimas permiten distinguir salud de autenticación. | Un 200 en salud y un 401 en sesión dejan sin observar la operación del vendedor. | Registrar el SHA servido junto con una venta aceptada y otra rechazada en la misma sesión de ensayo. |
| Javier Carta · [PR de interfaz](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15), firma por confirmar | Reutilizar la selección de pestañas simplificó la navegación desde Inicio. | El recorrido anterior omitía el retorno a Inicio y los dos estados del botón de salida. | Verificar la vista activa después de cada toque y probar la presencia del control en ambas configuraciones. |

[backend]: https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/6c031e04df3f8539d8166d609e29830b365eef18
[cliente]: https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/061ff1e112eb32a27c7293b240b94132a49982ef
[s16]: https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/semana-16-final.md
[corte]: https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/corte-final-2026-11-25.md
[ensayos]: docs/verificacion-final.md#comprobaciones-del-27-de-noviembre-de-2026
