# Complementario · Despliegue

```mermaid
C4Deployment
    title Despliegue — InvenTrack

    Deployment_Node(dev, "Dispositivo del usuario", "Windows, Android o iOS") {
        Container(flutter, "Cliente Flutter", "Dart")
    }

    Deployment_Node(dokploy, "Dokploy institucional", "inventrack.iscoutb.dev, TLS en el proxy") {
        Deployment_Node(compose, "Docker Compose (deploy/compose.lab.yaml)", "0.5 CPU, 256 MB, healthcheck /health") {
            Container(apiD, "API InvenTrack", "python:3.11-slim, uvicorn :10000, INVENTRACK_ENV=production")
        }
        Deployment_Node(vol, "Volumen Docker datos", "/app/data") {
            ContainerDb(dbD, "inventrack.sqlite3", "SQLite WAL")
        }
    }

    Deployment_Node(gh, "GitHub", "ISCOUTB/AS_202620_InvenTrack") {
        Container(ci, "GitHub Actions", "test.yml: análisis y pruebas Flutter, pytest, SonarCloud, contrato OpenAPI y pip-audit")
    }

    Rel(flutter, apiD, "HTTPS + Bearer")
    Rel(apiD, dbD, "Lee y escribe")
```

## Configuración por entorno

| Variable | Dokploy (compose) |
|---|---|
| `INVENTRACK_ENV` | `production` |
| `INVENTRACK_DB_PATH` | `/app/data/inventrack.sqlite3` |
| `INVENTRACK_ALLOW_BUSINESS_DATA` | `false` por defecto; `true` para activar el negocio |
| `INVENTRACK_INTERNAL_TOKEN` | obligatorio |
| `INVENTRACK_SMTP_*` | opcionales (HOST, PUERTO, DE, PARA, USUARIO, CLAVE) |

## Estado verificable desde el repositorio

- La sonda institucional obtuvo 200 en `/health` y 401 sin credencial en `/sesion`. [Resultados](../docs/verificacion-final.md#verificación-pública-y-colaboración).
