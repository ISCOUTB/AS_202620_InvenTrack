# Despliegue, observabilidad y costos

## Estado de la evidencia

| Evidencia | Implementación | Estado / dato a registrar |
|---|---|---|
| URL pública desde fuera de la universidad | Azure Container Apps, HTTPS | `POR_REGISTRAR: URL entregada por Terraform` |
| Infraestructura como código | [`infra/`](../infra) y [`Dockerfile`](../Dockerfile) | Versionada |
| Pipeline | [`test.yml`](../.github/workflows/test.yml) y [`deploy.yml`](../.github/workflows/deploy.yml) | El primero prueba y construye; el segundo despliega y hace smoke test |
| Health check | `GET /health` | El workflow lo valida después de `terraform apply` |
| Logs estructurados | JSON por línea en stdout | Evento `http_request`, sin credenciales ni cuerpos |
| Métrica consultable | `GET /metrics` | Formato Prometheus; contadores por método y ruta |
| Protección de secretos | `.env` ignorado, `.env.example` sin valores y secretos de GitHub | Credenciales Azure y estado Terraform son secretos del environment |
| Run exitoso | GitHub Actions, workflow `Deploy API` | `POR_REGISTRAR: <URL del run>` |

La URL no se inventa en el repositorio: queda registrada como salida
`service_url` después de crear el servicio Container Apps con Terraform. Debe
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

- **Azure Container Apps:** consume recursos cuando hay réplicas activas y
  puede escalar a cero. Azure requiere una suscripción con facturación; se
  deben configurar alertas presupuestarias y revisar la cuota gratuita vigente.
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

1. Crear una suscripción Azure, habilitar facturación y crear la cuenta de
  almacenamiento que guardará el estado remoto de Terraform.
2. Crear un service principal y configurar `AZURE_CREDENTIALS`,
  `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`,
  `AZURE_CLIENT_SECRET`, `AZURE_TF_STORAGE_ACCOUNT` y
  `AZURE_TF_STORAGE_RESOURCE_GROUP` como secrets del environment `production`
  en GitHub.
3. Ejecutar `Deploy API` manualmente o hacer push a `main`.
4. Conservar el enlace al run verde, la salida de `service_url` y la respuesta
  de `/health` desde una red
   externa en la entrega.
