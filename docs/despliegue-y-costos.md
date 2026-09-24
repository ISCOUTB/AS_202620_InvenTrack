# Despliegue, observabilidad y costos

## Estado de la evidencia

| Evidencia | Implementación | Estado / dato a registrar |
|---|---|---|
| URL pública desde fuera de la universidad | Render Web Service, HTTPS | `POR_REGISTRAR: https://inventrack-api.onrender.com` |
| Infraestructura como código | [`render.yaml`](../render.yaml) y [`Dockerfile`](../Dockerfile) | Versionada |
| Pipeline | [`test.yml`](../.github/workflows/test.yml) y [`deploy.yml`](../.github/workflows/deploy.yml) | El primero prueba y construye; el segundo despliega y hace smoke test |
| Health check | `GET /health` | Render lo consulta mediante `healthCheckPath` |
| Logs estructurados | JSON por línea en stdout | Evento `http_request`, sin credenciales ni cuerpos |
| Métrica consultable | `GET /metrics` | Formato Prometheus; contadores por método y ruta |
| Protección de secretos | `.env` ignorado, `.env.example` sin valores y secretos de GitHub | `RENDER_DEPLOY_HOOK` es secreto; `PUBLIC_API_URL` es variable de entorno del ambiente |
| Run exitoso | GitHub Actions, workflow `Deploy API` | `POR_REGISTRAR: <URL del run>` |

La URL no se inventa en el repositorio: queda registrada después de crear el
servicio Render desde `render.yaml`. Debe abrirse desde una conexión fuera de
la red universitaria. El smoke test del workflow falla si no se configura
`PUBLIC_API_URL`, por lo que no puede confundirse un despliegue no realizado
con uno válido.

## Prueba externa

Desde una red doméstica o móvil, sustituir `<PUBLIC_API_URL>` por la URL
registrada y ejecutar:

```powershell
curl.exe --fail https://<PUBLIC_API_URL>/health
curl.exe --fail https://<PUBLIC_API_URL>/metrics
```

Resultado esperado del primer comando:

```json
{"status":"ok","service":"InvenTrack"}
```

La segunda respuesta contiene, como mínimo, las series
`inventrack_http_requests_total` y
`inventrack_http_request_duration_seconds_total`.

## Secretos

No se almacenan secretos en el código ni en el manifiesto. La configuración
requerida para el ambiente `production` es:

- `RENDER_DEPLOY_HOOK`: secreto de GitHub Actions, usado solo para solicitar el
  despliegue.
- `PUBLIC_API_URL`: variable `production` de GitHub Actions; no es un secreto,
  porque una URL pública no necesita ocultarse.

En Render, cualquier credencial futura debe configurarse en Environment como
Secret y referenciarse mediante variables de entorno. `.env` está incluido en
`.gitignore`; `.env.example` contiene únicamente nombres y valores seguros.

## Estimación mensual

La estimación usa el escenario inicial del MVP y separa las cuatro magnitudes
solicitadas por la guía. El resultado esperado dentro de la capa gratuita es
cero; los supuestos son los que deben revisarse si cambia el tráfico.

| Magnitud | Supuesto mensual | Cómo se obtiene |
|---|---:|---|
| Operaciones | 50.000 peticiones | 25 negocios piloto x 2.000 peticiones |
| Datos almacenados | 0,10 GB | Catálogo y movimientos del MVP; actualmente el repositorio es in-memory |
| Tráfico de salida | 1 GB | Respuestas JSON pequeñas, aproximadamente 20 KB por petición |
| Ejecución | 50.000 invocaciones x 0,2 s = 10.000 s = 2,78 h | Duración media objetivo menor que el p95 declarado de 400 ms |

### Costo estimado

- **Render Web Service free:** USD 0/mes mientras el servicio y sus límites de
  capa gratuita cubran el escenario anterior. La capa gratuita debe verificarse
  en la cuenta antes de activar el servicio; no se registra una tarjeta como
  supuesto del proyecto.
- **GitHub Actions:** USD 0/mes para este repositorio público, sujeto a la
  política vigente de GitHub.
- **Total monetario estimado:** **USD 0/mes** bajo esos supuestos.

Punto de ruptura que debe recalcularse al cambiar de escenario: 2.000.000 de
peticiones/mes implicarían 400.000 s = 111,11 h de ejecución a 0,2 s por
petición, además de 40 GB de salida si se conserva el tamaño medio. En ese
punto no se asume que siga siendo gratis: se debe consultar el precio vigente
del proveedor y comparar con el servidor del laboratorio.

También se registra el costo no monetario: configurar el servicio toma una
persona aproximadamente 15 minutos; el redepliegue queda reproducible por
cualquier integrante que tenga acceso al repositorio y a los secretos del
environment `production`; el pipeline tarda el tiempo de instalación, pruebas,
build y arranque del servicio.

## Operación reproducible

1. Crear el Blueprint de Render desde `render.yaml` y confirmar que el servicio
   tiene URL pública.
2. Configurar `RENDER_DEPLOY_HOOK` como secret y `PUBLIC_API_URL` como variable
   del environment `production` en GitHub.
3. Ejecutar `Deploy API` manualmente o hacer push a `main`.
4. Conservar el enlace al run verde y la salida de `/health` desde una red
   externa en la entrega.
