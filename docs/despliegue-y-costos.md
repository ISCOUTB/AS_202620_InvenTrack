# Despliegue, observabilidad y costos

## Estado de la evidencia

| Evidencia | Implementación | Estado / dato a registrar |
|---|---|---|
| URL pública desde fuera de la universidad | Render, HTTPS | `POR_REGISTRAR: URL entregada por Render` |
| Infraestructura como código | [`render.yaml`](../render.yaml) y [`Dockerfile`](../Dockerfile) | Versionada; Terraform queda como alternativa Azure no utilizada |
| Pipeline | Render Auto Deploy desde `main` y [`test.yml`](../.github/workflows/test.yml) | Render construye y despliega; GitHub valida pruebas |
| Health check | `GET /health` | Configurado como health check de Render |
| Health check | `GET /health` | El workflow lo valida después del despliegue en App Service |
| Logs estructurados | JSON por línea en stdout | Evento `http_request`, sin credenciales ni cuerpos |
| Métrica consultable | `GET /metrics` | Formato Prometheus; contadores por método y ruta |
| Protección de secretos | `.env` ignorado, `.env.example` sin valores y secretos de GitHub | Credenciales Azure y estado Terraform son secretos del environment |
| Run exitoso | Render Deploy + GitHub Actions `Run Tests` | `POR_REGISTRAR: enlaces del deploy y del run` |

La URL se obtiene al crear el Web Service en Render. Debe abrirse desde una
conexión fuera de la red universitaria.

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

- `AZURE_CREDENTIALS`: JSON de una aplicación/service principal con permisos
  para crear recursos en la suscripción.
- `AZURE_SUBSCRIPTION_ID`: identificador de la suscripción Azure.
- `AZURE_TENANT_ID`, `AZURE_CLIENT_ID` y `AZURE_CLIENT_SECRET`: credenciales
  del service principal.
- `AZURE_TF_STORAGE_ACCOUNT`: cuenta de almacenamiento Azure donde vive el
  estado remoto.
- `AZURE_TF_STORAGE_RESOURCE_GROUP`: resource group de esa cuenta de estado.

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

- **Render:** el plan Free puede suspender el servicio por inactividad; el
  costo estimado es USD 0 bajo los límites y políticas vigentes del plan.
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

1. Crear un Web Service en Render conectado al repositorio y seleccionar
  `Docker` como runtime.
2. Mantener Auto Deploy habilitado para la rama `main`.
3. Conservar la URL pública, el enlace al deploy verde y el run verde de
  GitHub Actions.
4. Conservar las respuestas de `/health` y `/metrics` desde una red externa.
