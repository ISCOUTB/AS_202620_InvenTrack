# Verificación posterior a S15 · 19 de noviembre de 2026

## Escenarios de negocio

Tres corridas sobre Uvicorn en Windows, Python 3.11, HTTP por loopback, SQLite en archivo y un actor de ensayo autenticado. Cada corrida creó un SKU nuevo. ESC-01 lanzó 50 salidas distintas sobre 40 unidades. En cada corrida hubo 40 respuestas 200 con saldos consecutivos de 39 a 0 y diez respuestas 409. Repetir una clave exitosa reprodujo la respuesta original y el saldo siguió en cero. Para ESC-04 se calentó la lectura y se programaron 40 consultas de stock espaciadas 50 ms. Cada respuesta fue 200 con el saldo esperado. Los p95 por rango más cercano fueron 9,169, 14,095 y 8,000 ms frente a 400 ms. Las marcas de inicio permiten inspeccionar el espaciamiento efectivo. [Muestras individuales](retos/escenarios-2026-11-19.json) · [prueba reproducible](../tests/inventario/test_escenarios_calidad.py).

El reto anterior de 20 escrituras conserva su propio umbral y sus [cinco corridas del 15 de noviembre](retos/resultados-concurrencia-2026-11-15.json). Para repetir el nuevo ensayo por red, usar una instancia dedicada con datos desechables, configurar `INVENTRACK_ENSAYO_URL`, `INVENTRACK_ENSAYO_TOKEN` de un administrador de prueba y `INVENTRACK_ENSAYO_JSON` con la ruta de salida. Ejecutar `python -m pytest -q tests/inventario/test_escenarios_calidad.py`. Sin URL la prueba usa ASGI local. El experimento crea productos y movimientos.

## Disponibilidad pública

Comprobación pública verificada el 22 de noviembre de 2026:
- **Dokploy (`https://inventrack.iscoutb.dev/health`):** Responde `200 OK` con cuerpo `{"status":"ok","service":"InvenTrack"}`. La sonda de salud confirma que la instancia del servicio se encuentra activa y operativa en el subdominio institucional.
- **Render (`https://inventrack-api.onrender.com/health`):** Se mantiene como entorno secundario de contingencia.
- **Política de exposición en producción:** Conforme al [ADR-0018](adr/0018-restringir-superficies-internas-en-produccion.md), las superficies de negocio (`/productos`, `/inventario`) responden de forma preventiva con `503 Service Unavailable` mientras `INVENTRACK_ALLOW_BUSINESS_DATA=false`. Las rutas internas (`/docs`, `/redoc`, `/openapi.json`, `/metrics`) responden `404 Not Found` ante peticiones que no presenten el token interno por cabecera `X-Internal-Token`.

*(Registro histórico previo: consultas anónimas del 19 de noviembre reportaron 404 transitorio antes de la estabilización del despliegue).* [Dokploy](https://inventrack.iscoutb.dev/health) · [Render](https://inventrack-api.onrender.com/health).

## Integración continua y Quality Gate

El [workflow](../.github/workflows/test.yml) ejecuta el scanner y espera el gate. La [configuración](../sonar-project.properties) selecciona el proyecto público de la organización isco-utb. La consulta de jobs de GitHub mostró el paso SonarCloud Scan exitoso en los siguientes runs. Los enlaces de la última columna fijan el análisis individual consultado, independiente del estado posterior de main.

| Corte en main | Run con scanner | Estado público por revisión |
|---|---|---|
| S13 · 190db13 | [41386451056](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/41386451056) | No se encontró el hash exacto en el [historial público de análisis](https://sonarcloud.io/api/project_analyses/search?project=ISCOUTB_AS_202620_InvenTrack&ps=100). En la consulta del periodo del 1 de octubre al 15 de noviembre de 2026 figuraban cuatro análisis y ninguno correspondía al hash de S13. El gate de esa revisión sigue sin acreditar. |
| S14 · 2f33856 | [42556529986](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/42556529986) | [OK](https://sonarcloud.io/api/qualitygates/project_status?analysisId=9c869869-c4a9-48cc-bd26-0cd6193be37d) |
| S15 · b36f889 | [43789460138](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/43789460138) | [OK](https://sonarcloud.io/api/qualitygates/project_status?analysisId=20a21c0a-aa2c-4e02-ba82-c7ec1a0a141a) |
| Revisión evaluada · 95baaf0 | [44051745711](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/44051745711) | [OK](https://sonarcloud.io/api/qualitygates/project_status?analysisId=6bb24866-c09b-4f9f-ba0f-7f369075f821) |
| S16 · 1e3e632 (borrador) | [45102554695](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/45102554695) | [OK](https://sonarcloud.io/api/qualitygates/project_status?analysisId=4a492c1a-f085-426f-bfc1-be15038b7de7) |

En la revisión S16 indicada pasaron los jobs de pruebas del backend, Flutter y auditoría de dependencias, además del análisis de SonarCloud. La [preparación de S16](preparacion-s16.md) conserva el criterio para fijar la revisión al cierre. Los permisos de rama y la autoría individual del equipo requieren verificación en GitHub y por el docente. Las reescrituras históricas de ADR constan en [ADR-0009](adr/0009-consolidacion-inmutabilidad-adrs-previos.md). Los commits posteriores identificados en ADR-0012 (`ab80c28`) y ADR-0016 (`1269ffb`) corresponden a ratificación de estado ("Pendiente" a "Aceptado") y adición de detalles de observabilidad/deduplicación realizados el mismo día de su creación (25 de octubre), sin alteraciones de diseño sustantivas. Las decisiones nuevas se agregan estrictamente como sucesoras. [Evaluación original](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/evaluacion-s13-s14-s15-2026-11-17.md) · [contrato del curso](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/CONTRATO.md).

## Verificación local

El 19 de noviembre pasaron 37 pruebas Python, incluidas las de contrato OpenAPI, y nueve pruebas Flutter. El analizador de Flutter terminó sin hallazgos.

## Restauración, auditoría e historial

La [prueba del perfil durable](../tests/test_perfil_durable.py) inicia procesos separados, compara el saldo antes y después de restaurar una copia, reproduce una respuesta idempotente y comprueba un solo movimiento y evento con actor. También fuerza un fallo al registrar el evento y comprueba que la transacción revierte. La suite verifica la revocación por rotación y las respuestas de acceso denegado.

El barrido de los 305 commits alcanzables desde 95baaf0 encontró cero archivos con los prefijos de claves AWS, GitHub, Slack, OpenAI o cabeceras de clave privada buscados. Tampoco aparecieron archivos llamados .env en el historial consultado. Esta comprobación se limita a esos patrones. El registro de IA documenta esta intervención posterior al cierre.
