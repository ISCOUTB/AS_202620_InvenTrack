# Verificación técnica de InvenTrack · S15 y S16

## Escenarios de negocio

Tres corridas sobre Uvicorn en Windows, Python 3.11, HTTP por loopback, SQLite en archivo y un actor de ensayo autenticado. Cada corrida creó un SKU nuevo. ESC-01 lanzó 50 salidas distintas sobre 40 unidades. En cada corrida hubo 40 respuestas 200 con saldos consecutivos de 39 a 0 y diez respuestas 409. Repetir una clave exitosa reprodujo la respuesta original y el saldo siguió en cero. Para ESC-04 se calentó la lectura y se programaron 40 consultas de stock espaciadas 50 ms. Cada respuesta fue 200 con el saldo esperado. Los p95 por rango más cercano fueron 9,169, 14,095 y 8,000 ms frente a 400 ms. Las marcas de inicio permiten inspeccionar el espaciamiento efectivo. [Muestras individuales](retos/escenarios-2026-11-19.json) · [prueba reproducible](../tests/inventario/test_escenarios_calidad.py).

El reto anterior de 20 escrituras conserva su propio umbral y sus [cinco corridas del 15 de noviembre](retos/resultados-concurrencia-2026-11-15.json). Para repetir el nuevo ensayo por red, usar una instancia dedicada con datos desechables, configurar `INVENTRACK_ENSAYO_URL`, `INVENTRACK_ENSAYO_TOKEN` de un administrador de prueba y `INVENTRACK_ENSAYO_JSON` con la ruta de salida. Ejecutar `python -m pytest -q tests/inventario/test_escenarios_calidad.py`. Sin URL la prueba usa ASGI local. El experimento crea productos y movimientos.

## Conciliación por SKU

En el ensayo, tanto el inventario como el conteo físico sumaron 35 unidades. La comparación por producto detectó dos unidades faltantes de ARROZ, dos sobrantes de CAFE, la omisión de SAL (saldo cero) y el SKU OTRO fuera del corte. TE, desactivado y con cinco unidades, coincidió. Una venta posterior redujo ARROZ a 19 en la aplicación y el corte conservó las 20 unidades originales. Con el conteo corregido quedaron cero incidencias.

La prueba verifica también la integridad de la copia SQLite. Se reproduce desde la raíz con `python -m pytest -q tests/inventario/test_conciliacion_turno.py`. Para comparar datos propios, `python -m scripts.conciliar_conteo cierre.sqlite3 conteo.csv` lee una copia y un CSV con cabecera `sku,cantidad`. Devuelve un informe JSON y termina con código 0 si coincide, 1 si hay diferencias o 2 si la entrada es inválida. [Prueba de conciliación](../tests/inventario/test_conciliacion_turno.py) · [herramienta](../scripts/conciliar_conteo.py).

## Disponibilidad pública

Comprobación pública verificada el 22 de noviembre de 2026:
- **Dokploy (`https://inventrack.iscoutb.dev/health`):** Responde `200 OK` con cuerpo `{"status":"ok","service":"InvenTrack"}`. La sonda de salud confirma que la instancia del servicio se encuentra activa y operativa en el subdominio institucional.
- **Política de exposición en producción:** Conforme al [ADR-0018](adr/0018-restringir-superficies-internas-en-produccion.md), las superficies de negocio (`/productos`, `/inventario`) responden de forma preventiva con `503 Service Unavailable` mientras `INVENTRACK_ALLOW_BUSINESS_DATA=false`. Las rutas internas (`/docs`, `/redoc`, `/openapi.json`, `/metrics`) responden `404 Not Found` ante peticiones que no presenten el token interno por cabecera `X-Internal-Token`.

*(Registro histórico previo: consultas anónimas del 19 de noviembre reportaron 404 transitorio antes de la estabilización del despliegue).* [Dokploy](https://inventrack.iscoutb.dev/health).

## Integración continua y Quality Gate

El [workflow](../.github/workflows/test.yml) ejecuta el scanner y espera el gate. La [configuración](../sonar-project.properties) selecciona el proyecto público de la organización isco-utb. La consulta de jobs de GitHub mostró el paso SonarCloud Scan exitoso en los siguientes runs. Los enlaces de la última columna fijan el análisis individual consultado, independiente del estado posterior de main.

| Corte en main | Run con scanner | Estado público por revisión |
|---|---|---|
| S13 · 190db13 | [41386451056](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/41386451056) | No se encontró el hash exacto en el [historial público de análisis](https://sonarcloud.io/api/project_analyses/search?project=ISCOUTB_AS_202620_InvenTrack&ps=100). En la consulta del periodo del 1 de octubre al 15 de noviembre de 2026 figuraban cuatro análisis y ninguno correspondía al hash de S13. El gate de esa revisión sigue sin acreditar. |
| S14 · 2f33856 | [42556529986](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/42556529986) | [OK](https://sonarcloud.io/api/qualitygates/project_status?analysisId=9c869869-c4a9-48cc-bd26-0cd6193be37d) |
| S15 · b36f889 | [43789460138](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/43789460138) | [OK](https://sonarcloud.io/api/qualitygates/project_status?analysisId=20a21c0a-aa2c-4e02-ba82-c7ec1a0a141a) |
| Revisión evaluada · 95baaf0 | [44051745711](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/44051745711) | [OK](https://sonarcloud.io/api/qualitygates/project_status?analysisId=6bb24866-c09b-4f9f-ba0f-7f369075f821) |
| S16 · 1e3e632 (revisión verificada) | [45102554695](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/45102554695) | [OK](https://sonarcloud.io/api/qualitygates/project_status?analysisId=4a492c1a-f085-426f-bfc1-be15038b7de7) |

En la revisión S16 indicada pasaron los jobs de pruebas del backend, Flutter y auditoría de dependencias, además del análisis de SonarCloud. Los permisos de rama y la autoría individual del equipo requieren verificación en GitHub y por el docente. Las reescrituras históricas de ADR constan en [ADR-0009](adr/0009-consolidacion-inmutabilidad-adrs-previos.md). Los commits posteriores identificados en ADR-0012 (`ab80c28`) y ADR-0016 (`1269ffb`) corresponden a ratificación de estado ("Pendiente" a "Aceptado") y adición de detalles de observabilidad/deduplicación realizados el mismo día de su creación (25 de octubre), sin alteraciones de diseño sustantivas. Las decisiones nuevas se agregan estrictamente como sucesoras. [Evaluación original](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/evaluacion-s13-s14-s15-2026-11-17.md) · [contrato del curso](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/CONTRATO.md).

## Verificación local

El 19 de noviembre pasaron 37 pruebas Python, incluidas las de contrato OpenAPI, y nueve pruebas Flutter. El analizador de Flutter terminó sin hallazgos.

## Restauración, auditoría e historial

La [prueba del perfil durable](../tests/test_perfil_durable.py) inicia procesos separados, compara el saldo antes y después de restaurar una copia, reproduce una respuesta idempotente y comprueba un solo movimiento y evento con actor. También fuerza un fallo al registrar el evento y comprueba que la transacción revierte. La suite verifica la revocación por rotación y las respuestas de acceso denegado.

El barrido de los 305 commits alcanzables desde 95baaf0 encontró cero archivos con los prefijos de claves AWS, GitHub, Slack, OpenAI o cabeceras de clave privada buscados. Tampoco aparecieron archivos llamados .env en el historial consultado. Esta comprobación se limita a esos patrones. El registro de IA documenta esta intervención posterior al cierre.

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

**Verificación local de las funciones de Gestión.** Pasaron 48 pruebas de Python y 10 de Flutter. El análisis estático de Flutter terminó sin hallazgos. Además de la prueba de navegación, el cliente HTTP de la aplicación se conectó por loopback a Uvicorn en los perfiles de demostración y SQLite. Se comprobó el directorio, el historial, la conciliación contra un saldo anterior a la venta y, con credencial administrativa, la creación, el cambio de rol, la rotación y la revocación de un usuario. La prueba SMTP recibió un correo al reiniciar con un aviso pendiente. [Pruebas del backend](../tests/test_gestion_integrada.py) · [navegación en Flutter](../frontend/test/gestion_page_test.dart) · [decisión de correo](adr/0022-entregar-alertas-de-stock-desde-sqlite.md).

## Verificación pública y colaboración

El 22/11/2026 a las 04:29 UTC−5 se consultó Dokploy sin credenciales. `GET /health` devolvió 200 y el identificador InvenTrack (1,641 s). `GET /inventario/S16-CONSULTA` devolvió 503 con el mensaje de negocio deshabilitado (0,339 s). `GET /s16-ruta-inexistente` devolvió 404 (0,314 s). La sonda solo acredita ese instante. [Salud](https://inventrack.iscoutb.dev/health) · [Compose](../deploy/compose.lab.yaml).

Tras la activación comunicada por el equipo, se repitieron las lecturas públicas en Dokploy. `GET /health` devolvió **200**. Tanto `GET /productos` como `GET /inventario/S16-CONSULTA` devolvieron **401** con el detalle `Credencial individual requerida`. El cambio de 503 a 401 confirma que las rutas de negocio ya alcanzan la autenticación.

**Prueba manual autenticada.** El equipo reportó que creó un producto desde Flutter contra Dokploy y registró una entrada. La primera salida se aplicó y el saldo mostrado coincidió con el esperado. En la segunda se solicitó una cantidad superior a las existencias disponibles y la operación fue rechazada. Durante la prueba, la tarjeta de existencias mostró «Stock bajo» cuando el producto tenía pocas unidades.

En la comprobación pública posterior a los cambios locales de Gestión, Dokploy respondió 200 a `GET /health` y 404 a `GET /sesion`. El 22/11/2026 a las 22:15 UTC−5 se confirmaron 200 en `/health`, 401 en `/sesion` sin credencial y 404 en una ruta inexistente. En las comprobaciones de acceso sin credencial, `/sesion`, `/proveedores`, `/cierres` y `/usuarios` respondieron 401. Una ruta inexistente respondió 404.

**Comprobaciones manuales confirmadas por el equipo.** El equipo probó Gestión desde Flutter con una credencial de ensayo contra Dokploy y confirmó la recepción del correo de stock bajo por SMTP. Para comprobar la recuperación fuera del host, transfirió el respaldo SQLite a su PC, lo restauró como `recuperada.sqlite3` y consultó la API local desde Flutter en `http://127.0.0.1:8001`.

**Repetición cronometrada fuera del host.** Con el respaldo de 86 016 bytes ya disponible en el PC, transcurrieron **1,738 s** frente al objetivo de **120 s** en una ejecución. El cronómetro comenzó al copiar el respaldo a un directorio temporal e incluyó restaurar una base nueva con el comando de respaldo, emitir una credencial de lector de ensayo en esa base, iniciar Uvicorn y consultar un SKU por HTTP. Se detuvo tras recibir 200 y verificar que el SKU y la cantidad coincidían con los del respaldo. La descarga desde Dokploy ya se había completado antes de iniciar el cronómetro. La medición cubre la recuperación local con copia disponible. El tiempo de reponer el servicio público tras perder el host sigue sin medirse.

Entre las revisiones `539840b` (S10) y `1563759` (S16), `git diff --shortstat` contabilizó 201 archivos, 20 426 inserciones y 433 eliminaciones. En la segunda revisión se ejecutaron las pruebas del backend, de Flutter y la auditoría de dependencias. [Diferencia entre revisiones](https://github.com/ISCOUTB/AS_202620_InvenTrack/compare/539840b...1563759) · [ejecución de CI](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/45103793565).

El historial de la revisión publicada contiene los siguientes aportes por mes de autoría, agrupados por persona, incluidos merges. Se usaron `git shortlog -sne 1563759`, `git log --format="%as %an" 1563759`, correos coincidentes y referencias del curso. Dos commits de José fechados en febrero de 2025 quedan fuera de la tabla. Los ejemplos identifican responsabilidades ejercidas. [Listado oficial](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/EQUIPOS.md) · [Planilla de correspondencias](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/planilla.md).

| Integrante y firmas | Ago | Sep | Oct | Nov | Aportes comprobables |
|---|---:|---:|---:|---:|---|
| Félix Taborda · FlexT21, Felix Taborda, negro | 13 | 59 | 21 | 28 | Perfil SQLite y escenarios (`df16ecb`), respaldo y pruebas (`ca2f4e8`). |
| José Vargas · Jose Vargas, Josephva24 | 70 | 60 | 33 | 3 | Simulador de mensajería (`5507934`), decisiones de almacenamiento (`87208d4`). |
| Esteban Peluffo · Esteban Peluffo | 13 | 6 | 5 | 11 | Amenazas y controles (`e12e765`), sincronización de catálogo (`335e524`). |
| Javier Carta · jxviercarta-a11y, atribución provisional en la planilla | 3 | 0 | 0 | 10 | C4 (`dd4ea1c`), interfaz y pruebas ([PR 15](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15)). |

La consulta pública encontró nueve PR, siete de Dependabot y dos de integrantes del equipo. Cada PR del equipo tenía un comentario automático del análisis de calidad. [Comentario del PR 15](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15#issuecomment-7073171914) · [comentario del PR 16](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/16#issuecomment-7090255636).
