# Complementario · Despliegue

```mermaid
flowchart TB
    %%{init: {"flowchart": {"nodeSpacing": 70, "rankSpacing": 90, "curve": "basis", "htmlLabels": true}, "themeVariables": {"fontSize": "15px"}}}%%
    subgraph dev ["Dispositivo del usuario · Windows, Android o iOS"]
        flutter["<b>Cliente Flutter</b><br/>Dart"]:::cont
    end

    subgraph dokploy ["Dokploy institucional · inventrack.iscoutb.dev (TLS en el proxy)"]
        direction TB
        subgraph compose ["Docker Compose · 0.5 CPU, 256 MB, healthcheck /health"]
            apiD["<b>API InvenTrack</b><br/>python:3.11-slim, uvicorn :10000<br/>INVENTRACK_ENV=production"]:::cont
        end
        subgraph vol ["Volumen Docker datos · /app/data"]
            dbD[("<b>inventrack.sqlite3</b><br/>SQLite WAL")]:::db
        end
    end

    subgraph gh ["GitHub · ISCOUTB/AS_202620_InvenTrack"]
        ci["<b>GitHub Actions</b><br/>test.yml: análisis y pruebas Flutter, pytest,<br/>SonarCloud, contrato OpenAPI y pip-audit"]:::cont
    end

    flutter -->|"HTTPS + Bearer"| apiD
    apiD -->|"Lee y escribe"| dbD

    classDef person fill:#08427b,stroke:#052e56,color:#ffffff
    classDef sys fill:#1168bd,stroke:#0b4884,color:#ffffff
    classDef ext fill:#999999,stroke:#6b6b6b,color:#ffffff
    classDef cont fill:#438dd5,stroke:#2e6295,color:#ffffff
    classDef comp fill:#85bbf0,stroke:#5d82a8,color:#000000
    classDef db fill:#438dd5,stroke:#2e6295,color:#ffffff
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
