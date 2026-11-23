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

    Deployment_Node(render, "Render (PaaS)", "inventrack-api.onrender.com, plan free, render.yaml") {
        Container(apiR, "API InvenTrack", "Docker, perfil cerrado, sin disco persistente")
    }

    Deployment_Node(gh, "GitHub", "ISCOUTB/AS_202620_InvenTrack") {
        Container(ci, "GitHub Actions", "test.yml: flutter analyze y test, pytest con cobertura, SonarCloud, contrato OpenAPI, pip-audit. deploy.yml: respaldo manual a Azure")
    }

    Rel(flutter, apiD, "HTTPS + Bearer")
    Rel(apiD, dbD, "Lee y escribe")
    Rel(ci, apiR, "Autodespliegue por commit")
```

## Configuración por entorno

| Variable | Dokploy (compose) | Render |
|---|---|---|
| `INVENTRACK_ENV` | `production` | `production` |
| `INVENTRACK_DB_PATH` | `/app/data/inventrack.sqlite3` | no definida |
| `INVENTRACK_ALLOW_BUSINESS_DATA` | `false` por defecto; `true` para activar el negocio | `false` |
| `INVENTRACK_INTERNAL_TOKEN` | obligatorio | no definida (docs y métricas ocultas) |
| `INVENTRACK_SMTP_*` | opcionales (HOST, PUERTO, DE, PARA, USUARIO, CLAVE) | no definidas |

## Estado verificable desde el repositorio

- Dokploy: el README documenta `/health` = 200 y `/sesion` = 404 en la última comprobación, es decir, el despliegue público aún no incluye las rutas de Gestión.
- Render: solo ofrece el perfil cerrado; las rutas de negocio responden 503.
- `deploy.yml` es un respaldo manual hacia Azure App Service (imagen en GHCR); no es el despliegue principal.
