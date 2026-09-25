# Despliegue, observabilidad y costos

## Estado de la evidencia

| Evidencia | Implementación | Estado / dato a registrar |
|---|---|---|
| URL pública desde fuera de la universidad | Google Cloud Run, HTTPS | `POR_REGISTRAR: URL entregada por Terraform` |
| Infraestructura como código | [`infra/`](../infra) y [`Dockerfile`](../Dockerfile) | Versionada |
| Pipeline | [`test.yml`](../.github/workflows/test.yml) y [`deploy.yml`](../.github/workflows/deploy.yml) | El primero prueba y construye; el segundo despliega y hace smoke test |
| Health check | `GET /health` | El workflow lo valida después de `terraform apply` |
| Logs estructurados | JSON por línea en stdout | Evento `http_request`, sin credenciales ni cuerpos |
| Métrica consultable | `GET /metrics` | Formato Prometheus; contadores por método y ruta |
| Protección de secretos | `.env` ignorado, `.env.example` sin valores y secretos de GitHub | `GCP_CREDENTIALS`, `GCP_PROJECT_ID` y `GCP_TF_STATE_BUCKET` son secretos del environment |
| Run exitoso | GitHub Actions, workflow `Deploy API` | `POR_REGISTRAR: <URL del run>` |

La URL no se inventa en el repositorio: queda registrada como salida
`service_url` después de crear el servicio Cloud Run con Terraform. Debe
abrirse desde una conexión fuera de la red universitaria.

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

- `GCP_CREDENTIALS`: credenciales de una cuenta de servicio con permisos para
  Artifact Registry, Cloud Run y el bucket de estado.
- `GCP_PROJECT_ID`: identificador del proyecto de Google Cloud.
- `GCP_TF_STATE_BUCKET`: nombre globalmente único del bucket GCS usado para el
  estado remoto de Terraform.

Las credenciales deben configurarse en GitHub como secrets y nunca entrar al
repositorio. `.env` está incluido en `.gitignore`; `.env.example` contiene
únicamente nombres y valores seguros.

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

- **Google Cloud Run:** la cuota gratuita cubre un MVP de bajo tráfico y el
  servicio escala a cero. Google Cloud requiere habilitar facturación, por lo
  que se deben configurar alertas presupuestarias.
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

1. Crear un proyecto de Google Cloud, habilitar facturación y activar las APIs
  de Cloud Run, Artifact Registry and Cloud Storage.
2. Crear una cuenta de servicio y configurar `GCP_CREDENTIALS`,
  `GCP_PROJECT_ID` y `GCP_TF_STATE_BUCKET` como secrets del environment
  `production` en GitHub.
3. Ejecutar `Deploy API` manualmente o hacer push a `main`.
4. Conservar el enlace al run verde, la salida de `service_url` y la respuesta
  de `/health` desde una red
   externa en la entrega.
