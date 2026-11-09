# Evidencia de CI, calidad y despliegue S12

## CI

El último run público consultado para `main` corresponde a la punta actual
documentada (`e17afb8ad59fba8c851e06338c1219f7f4bc918f`):

- Workflow: `Run Tests`
- Commit: `e17afb8ad59fba8c851e06338c1219f7f4bc918f`
- Resultado: `success`
- URL: <https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/42319774632>
- Jobs `test` y `dependency-audit`: `success`
- Workflow versionado: [`.github/workflows/test.yml`](../.github/workflows/test.yml)

El run incluye la suite de 34 pruebas, la validación del contrato OpenAPI y el
escaneo `pip-audit` con hashes. No constituye por sí solo evidencia de
redespliegue ni de funcionamiento público de Render o Dokploy.

## SonarCloud

El Quality Gate público consultado para el proyecto
`ISCOUTB_AS_202620_InvenTrack` fue `OK`:

- Proyecto: <https://sonarcloud.io/project/overview?id=ISCOUTB_AS_202620_InvenTrack>
- Estado verificable: <https://sonarcloud.io/api/qualitygates/project_status?projectKey=ISCOUTB_AS_202620_InvenTrack>
- Cobertura nueva reportada: `95.7`
- Duplicación nueva reportada: `0.0`
- Security hotspots revisados: `100.0`

La configuración local y el workflow son evidencia de ejecución. El estado del
Quality Gate para el proyecto y la revisión analizada se acredita con la
respuesta pública de la API:
<https://sonarcloud.io/api/qualitygates/project_status?projectKey=ISCOUTB_AS_202620_InvenTrack>.
Resultado: `OK`; cobertura nueva `95.4%`, duplicación nueva `0.0%` y security
hotspots revisados `100.0%`.

## Despliegue institucional y alternativa

La URL institucional declarada es <https://inventrack.iscoutb.dev>. La consulta
del 27 de octubre de 2026 no pudo resolver DNS/TLS para `/health` ni
`/metrics`; esa observación queda como evidencia histórica de ese corte y no
describe el estado vigente. La comprobación posterior de S13 verificó
`/health` con `200`, superficies internas con `404` sin token y rutas de negocio
con `503` preventivo. Esta evidencia S12 no afirma que la mensajería sea
consultable públicamente.

La alternativa Render respondió en la raíz durante esa consulta:

```text
Our server is running on port 10000
```

Sin embargo, `/health` y `/metrics` respondieron `503` durante la misma
consulta. Ese resultado es histórico y no representa el estado actual. La
aplicación local sí expone esas rutas y las métricas de mensajería se validan
en las pruebas; esta evidencia S12 no certifica el estado actual de Render.

## Criterio de publicación

La comprobación pública anterior no demuestra que el commit
`e17afb8ad59fba8c851e06338c1219f7f4bc918f` haya sido redesplegado ni que el
funcionamiento público actual coincida con ese commit.
Para repetir la evidencia operativa después del despliegue, se debe consultar:

```powershell
curl.exe -i https://inventrack.iscoutb.dev/health
curl.exe -i -H "X-Internal-Token: <TOKEN_GESTIONADO>" https://inventrack.iscoutb.dev/metrics
```

Se debe registrar el hash desplegado, el run de CI asociado y, usando el token
gestionado fuera del repositorio, la presencia de
`inventrack_messaging_messages_total` en `/metrics`.

El hash desplegado, la consulta autorizada con el token y la comprobación de
las URLs públicas quedan fuera de esta actualización porque requieren acceso
al proveedor de despliegue y un secreto externo.

## Estado interno verificado el 8 de noviembre de 2026

La punta local `e17afb8ad59fba8c851e06338c1219f7f4bc918f` fue validada con:

```powershell
.\.venv\Scripts\python.exe -m pytest -q
.\.venv\Scripts\python.exe -m pip check
.\.venv\Scripts\python.exe -m pip_audit -r requirements.txt --no-deps
```

Resultados: **34 pruebas aprobadas**, dependencias consistentes y ninguna
vulnerabilidad conocida reportada. Esta verificación local y el run de CI no
demuestran que el proveedor ya sirva esa punta; esa comprobación requiere
redespliegue externo.
