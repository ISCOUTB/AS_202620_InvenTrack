# Evidencia de CI, calidad y despliegue S12

## CI

El último run público consultado para `main` fue:

- Workflow: `Run Tests`
- Commit: `076c5a6b3b454f142caf29b50f6f0879c1cb77ee`
- Resultado: `success`
- URL: <https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/40570722782>
- Workflow versionado: [`.github/workflows/test.yml`](../.github/workflows/test.yml)

Ese run corresponde al último commit publicado en `main` al momento de la
consulta. Los cambios locales posteriores deben publicarse para obtener un run
que incluya la idempotencia HTTP de ADR-0017.

## SonarCloud

El Quality Gate público consultado para el proyecto
`ISCOUTB_AS_202620_InvenTrack` fue `OK`:

- Proyecto: <https://sonarcloud.io/project/overview?id=ISCOUTB_AS_202620_InvenTrack>
- Estado verificable: <https://sonarcloud.io/api/qualitygates/project_status?projectKey=ISCOUTB_AS_202620_InvenTrack>
- Cobertura nueva reportada: `95.7`
- Duplicación nueva reportada: `0.0`
- Security hotspots revisados: `100.0`

La configuración local y el workflow son evidencia de ejecución, pero el estado
del Quality Gate se acredita con la respuesta pública de la API anterior.

## Despliegue institucional y alternativa

La URL institucional declarada es <https://inventrack.iscoutb.dev>. En la
consulta del 27 de octubre de 2026 no fue posible resolver DNS/TLS para
`/health` ni `/metrics`; por tanto, el despliegue institucional queda **no
verificado** y no se afirma que la mensajería esté desplegada allí.

La alternativa Render respondió en la raíz:

```text
Our server is running on port 10000
```

Sin embargo, `/health` y `/metrics` respondieron `503` durante la misma
consulta. La aplicación local sí expone esas rutas y las métricas de
mensajería se validan en las pruebas; falta un despliegue verificable del
commit que contiene ADR-0017.

## Criterio de publicación

Después de publicar los cambios en `main`, se debe repetir esta evidencia con:

```powershell
curl.exe -i https://inventrack.iscoutb.dev/health
curl.exe -i https://inventrack.iscoutb.dev/metrics
```

y registrar el hash desplegado, el run de CI asociado y la presencia de
`inventrack_messaging_messages_total` en `/metrics`.
