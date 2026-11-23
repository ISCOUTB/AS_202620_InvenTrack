# Nivel 2 · Diagrama de contenedores

```mermaid
flowchart TB
    %%{init: {"flowchart": {"nodeSpacing": 70, "rankSpacing": 90, "curve": "basis", "htmlLabels": true}, "themeVariables": {"fontSize": "15px"}}}%%
    usuario(["<b>Usuario</b> (admin / operador / lector)<br/>Introduce su token individual<br/>en la pantalla de acceso"]):::person
    monitor["<b>Consumidor de métricas</b><br/>Prometheus u operador"]:::ext
    smtp["<b>Servidor SMTP</b><br/>Alertas de stock bajo"]:::ext

    subgraph sis ["InvenTrack"]
        direction TB
        app["<b>Cliente Flutter</b><br/>Dart / Flutter, provider, http<br/>Inicio, productos, inventario y gestión<br/>Windows, Android e iOS"]:::cont
        api["<b>API InvenTrack</b><br/>Python 3.11, FastAPI, Uvicorn<br/>Monolito modular hexagonal, Bearer y roles,<br/>métricas, logs JSON, broker simulado, cola de correo"]:::cont
        db[("<b>Base SQLite</b><br/>modo WAL<br/>usuarios, productos, stocks, movimientos,<br/>comandos, auditoria, proveedores,<br/>cierres, correos_stock")]:::db
        cli["<b>CLI de administración</b><br/>python -m ...<br/>Credenciales (emitir y revocar),<br/>respaldo y restauración"]:::cont
    end

    usuario -->|"Usa"| app
    app -->|"JSON / HTTPS<br/>Bearer"| api
    api -->|"Lee y escribe<br/>una transacción por petición"| db
    cli -->|"Credenciales y copias<br/>sqlite3"| db
    api -->|"Avisos de stock desde la cola<br/>SMTP + STARTTLS"| smtp
    monitor -->|"GET /metrics<br/>X-Internal-Token"| api

    classDef person fill:#08427b,stroke:#052e56,color:#ffffff
    classDef sys fill:#1168bd,stroke:#0b4884,color:#ffffff
    classDef ext fill:#999999,stroke:#6b6b6b,color:#ffffff
    classDef cont fill:#438dd5,stroke:#2e6295,color:#ffffff
    classDef comp fill:#85bbf0,stroke:#5d82a8,color:#000000
    classDef db fill:#438dd5,stroke:#2e6295,color:#ffffff
```

## Contenedores

| Contenedor | Tecnología | Evidencia en el repo |
|---|---|---|
| Cliente Flutter | Flutter, `provider`, `http`, `google_fonts`, `intl` | `frontend/pubspec.yaml`, `frontend/lib/services/api_service.dart` |
| API InvenTrack | FastAPI, imagen `python:3.11-slim`, usuario no root, puerto 10000 | `Dockerfile`, `app/main.py` |
| Base SQLite | Archivo único en volumen persistente `/app/data/inventrack.sqlite3` | `deploy/compose.lab.yaml`, `app/shared/infrastructure/sqlite.py` |
| CLI de administración | Módulos Python ejecutables dentro del mismo servicio y volumen | `credenciales.py`, `respaldo.py` |

## Perfiles de ejecución de la API

| Perfil | Condición | Persistencia | Autenticación |
|---|---|---|---|
| Demo | Sin `INVENTRACK_DB_PATH` | Repositorios en memoria | Ninguna |
| Durable | Con `INVENTRACK_DB_PATH` | SQLite | Bearer individual + roles |
| Producción cerrada | `INVENTRACK_ENV=production` sin `INVENTRACK_ALLOW_BUSINESS_DATA=true` | — | Rutas de negocio devuelven 503 |

## Endpoints expuestos por la API

`/health`, `/`, `/metrics`*, `/docs`*, `/redoc`*, `/openapi.json`*, `/sesion`, `/usuarios`, `/productos`, `/proveedores`, `/cierres`, `/inventario/{id}/entradas`, `/inventario/{id}/salidas`, `/inventario/{id}` y `/inventario/{id}/movimientos`.

\* Devuelven 404 en producción sin `X-Internal-Token` válido.
