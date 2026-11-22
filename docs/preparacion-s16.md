# Semana 16 de InvenTrack · borrador de trabajo

[Repositorio](https://github.com/ISCOUTB/AS_202620_InvenTrack) · [Sistema desplegado](https://inventrack.iscoutb.dev).

## Reto propuesto · conciliar el inventario al cierre de turno

Al cerrar la tienda, el encargado cuenta los productos mientras la siguiente caja se prepara para vender. ¿Puede identificar exactamente qué SKU falta o sobra al cierre, aunque las diferencias se compensen en el total y el saldo de la API ya haya cambiado? Los retos anteriores comprobaron la consistencia de los movimientos. Sobre esa base y el respaldo SQLite incorporado después de S15, el nuevo ensayo compara el saldo registrado con una observación independiente en la tienda.

El operador toma una copia con el [comando de respaldo](../app/shared/infrastructure/respaldo.py) en el corte acordado y registra el conteo de ese mismo instante en un CSV UTF-8 con columnas `sku,cantidad`. Se incluyen los productos activos, incluso sin existencias, y los desactivados que conservan saldo. Una cantidad explícita de cero acredita un SKU contado. Una fila omitida requiere revisión. Si el conteo físico se prolonga mientras cambia la mercancía, el operador debe separar los movimientos del turno siguiente.

| SKU | Saldo de la copia | Conteo del ensayo | Resultado esperado |
|---|---:|---:|---|
| ARROZ | 20 | 18 | Faltan 2 unidades |
| CAFE | 10 | 12 | Sobran 2 unidades |
| TE (desactivado) | 5 | 5 | Coincide |
| SAL | 0 | sin fila | Falta contar el SKU |
| OTRO | fuera del corte | 0 | Revisar identificación |

**Criterio de aceptación.** El control por total da 35 unidades en ambos lados. La conciliación debe señalar los cuatro SKU con incidencias, dejar TE sin marcar y dar cero incidencias con el conteo corregido. ARROZ debe conservar 20 como referencia aunque el saldo operativo baje a 19 después de la copia. El ensayo local verificó los cuatro hallazgos, cero falsos positivos y la integridad del archivo comparado. Es una propuesta para revisión del equipo. [Herramienta](../scripts/conciliar_conteo.py) · [Prueba reproducible](../tests/inventario/test_conciliacion_turno.py).

```sh
python -m pytest -q tests/inventario/test_conciliacion_turno.py
python -m scripts.conciliar_conteo cierre.sqlite3 conteo.csv
```

El segundo comando requiere una copia y un conteo propios. Emite un informe JSON. El código de salida es 0 si todo coincide, 1 si hay diferencias y 2 si la entrada es inválida. La herramienta abre la copia en modo de lectura. El ajuste de existencias, si procede, corresponde al encargado después de revisar el conteo.

## Referencias para preparar el corte

El equipo indicó que Moodle cierra el **22/11/2026 a las 23:55 UTC−5** y que no muestra un desafío específico. El hash publicado observado antes del cierre fue `522af50484dffddd2cb59bee9218ad0d66d40882`, de `2026-11-22T04:23:24-05:00`. Al cierre se podrá identificar la revisión con estos comandos.

```sh
git fetch origin main
git log -1 --format="%H %cI %s" --until="2026-11-22T23:55:00-05:00" origin/main
```

## Alcance desde el segundo corte

S10 se evaluó en `539840be57f8a0b719bb33e19d05031489a25b86`. Hasta la revisión publicada observada cambiaron 170 archivos, con 12 100 inserciones y 242 eliminaciones. Para reproducir el recuento, ejecutar `git diff --shortstat 539840b..522af50`. [Evaluación de S10](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/semana-10-corte2.md) · [Diferencia publicada](https://github.com/ISCOUTB/AS_202620_InvenTrack/compare/539840b...522af50).

| Compromiso o necesidad | Entrega comprobable | Límite |
|---|---|---|
| Catálogo, entradas, salidas e integridad | API y cliente Flutter. El historial impide el borrado físico. [Contrato](api/inventrack-contrato.md) | La instancia pública tiene el negocio cerrado. |
| Concurrencia por SKU y p95 ≤ 400 ms | Misma ráfaga en S10, S16 en memoria y S16 durable. [Muestras del candidato](retos/comparacion-s16-final.json) | Una instancia, proceso caliente y ASGI local. |
| Historial, idempotencia e identidad | SQLite conserva movimiento, saldo, evento con actor y resultado del reintento. [Restauración verificada](../tests/test_perfil_durable.py) | Gestión de usuarios por CLI. Broker y DLQ en memoria. Falta probar el RTO y la recuperación fuera del host institucional. |
| Gestión de proveedores y alertas automáticas | Siguen como objetivos del diseño inicial. [Ficha del problema](ficha_problema.md) | Pendientes el flujo de proveedores y la entrega de alertas por correo. La predicción de demanda quedó fuera del MVP. |

## Concurrencia y recuperación

Como antecedente del nuevo reto se conservan la mejora del escritor SQLite y las mediciones de los cortes anteriores.

Desde la raíz, con Python 3.11 y las dependencias del README, ejecutar `python scripts/comparar_concurrencia.py --actual trabajo --salida resultado-local.json`. El comando extrae el código S10 con Git, crea datos temporales y alterna los perfiles en tres rondas. Cada proceso crea el SKU de arroz, carga 100 unidades y recibe 20 salidas de una unidad, cada una con clave distinta. El p95 es la 19.ª latencia ordenada. Se conservan tiempos individuales, respuestas HTTP y saldos. La herramienta devuelve error si una corrida supera 400 ms. Para repetir la referencia publicada sustituir `trabajo` por `522af50`.

| Ensayo | p95 por corrida (ms) | Resultado |
|---|---|---|
| S10 en memoria, referencia repetida junto al candidato | 15,424 / 13,267 / 13,358 | 3 de 3 dentro del límite |
| S16 en memoria, mismo montaje | 25,795 / 25,283 / 24,471 | 3 de 3 |
| SQLite en el commit publicado, antes del ajuste | 341,296 / 771,660 / 388,914 | 2 de 3 |
| SQLite con conexión escritora reutilizada | 98,660 / 98,089 / 102,243 | 3 de 3 |

Cada corrida terminó con 20 respuestas 200, saldos consecutivos de 99 a 80 y stock final 80. La mediana de los p95 en SQLite bajó 290,254 ms (74,6 %) respecto del perfil durable publicado. El lector puede contrastar también las dos variantes intermedias en el ADR. Las tres rondas describen este equipo y esta carga. [Datos iniciales](retos/comparacion-s10-s16.json) · [Datos finales](retos/comparacion-s16-final.json) · [ADR-0021](adr/0021-serializar-escrituras-sqlite.md).

El ensayo distinto de ESC-01 y ESC-04, del 19 de noviembre, abrió una conexión HTTP real a Uvicorn y autenticó a un administrador de ensayo. En cada una de tres rondas, 50 salidas sobre 40 unidades dieron 40 éxitos y diez conflictos. El p95 de las consultas programadas a 20/s fue 9,169 / 14,095 / 8,000 ms. La prueba de restauración mantiene siete unidades y un solo movimiento al repetir la misma entrada tras recuperar la copia. [Muestras HTTP](retos/escenarios-2026-11-19.json) · [Procedimiento](verificacion-final.md) · [Prueba de recuperación](../tests/test_perfil_durable.py).

En S16 se repitió ese ensayo sobre Uvicorn en loopback, con la conexión escritora del candidato, una base desechable y un usuario autenticado. En cada ronda, 40 ventas se confirmaron, diez obtuvieron 409 y el saldo quedó en cero incluso al repetir la clave. Los tres p95 de lectura fueron **5,644 / 6,057 / 8,336 ms**. Con el ensayo de conciliación se ejecutaron 46 pruebas Python, todas aprobadas. En la verificación previa del cliente pasaron 9 pruebas Flutter. `flutter analyze --no-pub` terminó sin hallazgos. El verificador de CI recorrió los enlaces locales de 49 documentos y los cinco aspectos. [Muestras HTTP del candidato](retos/escenarios-s16-http.json) · [Prueba ejecutada](../tests/inventario/test_escenarios_calidad.py).

## Verificación pública y colaboración

El 22/11/2026 a las 04:29 UTC−5 se consultó Dokploy sin credenciales. `GET /health` devolvió 200 y el identificador InvenTrack (1,641 s). `GET /inventario/S16-CONSULTA` devolvió 503 con el mensaje de negocio deshabilitado (0,339 s). `GET /s16-ruta-inexistente` devolvió 404 (0,314 s). La sonda solo acredita ese instante. [Salud](https://inventrack.iscoutb.dev/health) · [Compose](../deploy/compose.lab.yaml).

El historial de la revisión publicada contiene los siguientes aportes por mes de autoría, agrupados por persona, incluidos merges. Se usaron `git shortlog -sne 522af50`, `git log --format="%as %an" 522af50`, correos coincidentes y referencias del curso. Dos commits de José fechados en febrero de 2025 quedan fuera de la tabla. Los ejemplos identifican responsabilidades ejercidas. [Listado oficial](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/EQUIPOS.md) · [Planilla de correspondencias](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/planilla.md).

| Integrante y firmas | Ago | Sep | Oct | Nov | Aportes comprobables |
|---|---:|---:|---:|---:|---|
| Félix Taborda · FlexT21, Felix Taborda, negro | 13 | 59 | 21 | 17 | Perfil SQLite y escenarios (`df16ecb`), respaldo y pruebas (`ca2f4e8`). |
| José Vargas · Jose Vargas, Josephva24 | 70 | 60 | 33 | 3 | Simulador de mensajería (`5507934`), decisiones de almacenamiento (`87208d4`). |
| Esteban Peluffo · Esteban Peluffo | 13 | 6 | 5 | 6 | Amenazas y controles (`e12e765`), sincronización de catálogo (`335e524`). |
| Javier Carta · jxviercarta-a11y, atribución provisional en la planilla | 3 | 0 | 0 | 10 | C4 (`dd4ea1c`), interfaz y pruebas ([PR 15](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15)). |

La API pública devolvió ocho PR, siete de Dependabot y el PR 15 del equipo. La consulta de comentarios de revisión en línea devolvió cero. El PR 15 tampoco tenía revisiones ni comentarios de conversación. Una revisión técnica real puede documentarse en el PR de integración antes del cierre. [PR del equipo](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15) · [Comentarios de revisión](https://api.github.com/repos/ISCOUTB/AS_202620_InvenTrack/pulls/comments).

## Matriz preliminar de la ficha S16

| Criterio | Estado al preparar la entrega | Evidencia u observación |
|---|---|---|
| Estado final anterior al cierre | No verificado | Se conoce rama, hora de cierre y candidato publicado. Falta resolver el hash después de las 23:55. |
| Sistema desplegado y estable | No verificado | Salud 200 a las 04:29. Una sola sonda y el negocio cerrado limitan la comprobación. |
| Flujos principales con datos realistas en despliegue | No cumple | Inventario institucional devolvió 503. El ensayo local de arroz sí confirmó catálogo, carga, ventas y saldo. |
| Caminos de error | Cumple | 404 público. En local se verifican 401, 403, 409, 422 y espera agotada 503 con reintento. [Pruebas](../tests/inventario/) · [Perfil durable](../tests/test_perfil_durable.py). |
| Desafío propuesto para S16 | En revisión | El ensayo local de conciliación identificó cuatro diferencias con totales iguales. Queda pendiente la revisión del equipo. [Prueba de cierre de turno](../tests/inventario/test_conciliacion_turno.py). |
| Alcance comprometido y recortes declarados | Cumple | Comparación S10, evidencia y límites en la tabla de alcance de este documento. |
| Evolución de decisiones | Cumple | [ADR en orden](adr/). 0001–0004 módulos y contrato, 0005–0009 despliegue y observabilidad, 0010–0017 integración y almacenamiento, 0018–0021 acceso y persistencia. |
| Decisión reemplazada o confirmada | Cumple | [ADR-0020](adr/0020-persistir-inventario-y-auditoria-en-sqlite.md) sucede a 0012/0014/0015 en SQLite. [ADR-0021](adr/0021-serializar-escrituras-sqlite.md) cuantifica el costo del escritor. |
| Atributos medidos con umbral | Cumple | Tres p95 de escrituras y tres de lecturas. ESC-03 conserva pendiente el RTO operativo. [Escenarios](verificacion-final.md). |
| Fallos y seguridad | Cumple | Rollback de auditoría, rotación, roles, timeout y restauración en la [suite](../tests/test_perfil_durable.py). El último [CI publicado](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/45007321733) corresponde al código anterior al ajuste. |
| arc42 completo con glosario | Cumple | [§1 a §12](arc42/arc42-template-EN.md), incluidos alcance, ejecución, riesgos y glosario específicos del proyecto. |
| C4 niveles 1–3 | Cumple | [Actores](c4/context.md), [contenedores](c4/containers.md), [componentes](c4/components.md). |
| Aspectos recorridos | Cumple | 5/5 en [la tabla](aspectos.md). ASP-01 enlaza validación de stock y recuperación. ASP-02 enlaza el escritor, el ensayo y sus muestras. ASP-03 lleva a métricas y p95. ASP-04 llega a eventos y deduplicación. ASP-05 llega a credenciales y pruebas 401/403. |
| Validación automática de documentación | Cumple | El [workflow](../.github/workflows/test.yml) ejecuta [el verificador](../scripts/verificar_trazabilidad.py) de destinos locales, anclas y eslabones de cada aspecto. Pendiente su primera ejecución remota. |
| Aportes del equipo | No verificado | Cuatro firmas con aportes de código y documentación. La planilla mantiene provisional la atribución de Javier. |
| Revisión cruzada con comentarios de fondo | No cumple | PR 15 sin revisiones ni comentarios al consultar GitHub. |
| Demostración y sustentación | No verificado | Pendiente de la sesión ante el jurado. |

## Matriz preliminar del contrato

| Criterio | Estado | Evidencia u observación |
|---|---|---|
| Organización, nombre y visibilidad | Cumple | La [API pública de GitHub](https://api.github.com/repos/ISCOUTB/AS_202620_InvenTrack) devolvió el nombre esperado, `private=false` y rama `main`. |
| Estructura mínima | Cumple | [README](../README.md), [arc42](arc42/), [ADR](adr/), [C4](c4/), [aspectos](aspectos.md) y [registro IA](ia.md). |
| Estado calificado identificable | No verificado | Resolución al cierre mediante el comando de la cabecera. |
| Nombres de ADR | Cumple | La numeración 0001–0021 en [el directorio](adr/) sigue la convención del contrato. |
| Inmutabilidad de ADR aceptados | No cumple | [ADR-0009](adr/0009-consolidacion-inmutabilidad-adrs-previos.md) registra reescrituras previas. La evolución de S16 se documenta en un sucesor. |
| IA al día | Cumple | [Registro del 22 de noviembre](ia.md). |
| Pipeline, SonarCloud y Quality Gate | No cumple | Para el candidato pendiente de integración falta el run y gate públicos. La revisión previa 522af50 sí los acredita. [Configuración](../sonar-project.properties), [paso 7 del job test](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/45007321733/job/137161676636), [Quality Gate OK](https://sonarcloud.io/api/qualitygates/project_status?analysisId=7fca55f3-b2aa-4ed8-9494-9d0cd33070fb). Falta el run del candidato local. La [rama](https://api.github.com/repos/ISCOUTB/AS_202620_InvenTrack/branches/main) devolvió `protected=false`; queda pendiente exigir checks exitosos para integrar. |
| Secretos | Cumple | En 726 blobs de los 321 commits alcanzables desde 522af50, cero firmas de clave privada o prefijos AWS/GitHub/Slack/OpenAI buscados y cero rutas `.env`. El patrón amplio señala referencias a variables y credenciales de prueba. `git log -S'BEGIN PRIVATE KEY'` encuentra el patrón escrito en documentación en `0b35348`. |
| Contribución por integrante | No verificado | Historial agrupado y atribución provisional en la tabla de colaboración. |

## Para la demostración pública

El operador de Dokploy debe confirmar el montaje y permisos del volumen `/app/data`, una copia restaurable fuera del host y las credenciales de ensayo. Con esos prerrequisitos puede activar `INVENTRACK_ALLOW_BUSINESS_DATA=true` en una instancia destinada a la demostración. El CLI del [README](../README.md) emite identidades individuales. La credencial de negocio se envía por HTTPS como Bearer y es distinta del secreto operativo de métricas. El jurado puede verificar el SKU desde Flutter o desde la API. Quedan a cargo del equipo la integración antes del cierre, el enlace al nuevo gate, la entrega en Moodle y la sustentación.
