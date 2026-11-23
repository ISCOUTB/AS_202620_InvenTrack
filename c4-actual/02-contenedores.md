# Nivel 2 · Diagrama de contenedores

```mermaid
C4Container
    title Contenedores — InvenTrack

    Person(usuario, "Usuario (admin / operador / lector)", "Introduce su token individual en la pantalla de acceso")

    System_Boundary(sis, "InvenTrack") {
        Container(app, "Cliente Flutter", "Dart / Flutter, provider, http", "Pantallas de inicio, productos, inventario y gestión (proveedores, usuarios, cierres). Windows, Android e iOS")
        Container(api, "API InvenTrack", "Python 3.11, FastAPI, Uvicorn", "Monolito modular hexagonal. Autenticación Bearer y roles, métricas Prometheus, logs JSON, broker de mensajería simulado y cola de correo")
        ContainerDb(db, "Base SQLite", "SQLite en modo WAL", "usuarios, productos, stocks, movimientos, comandos (idempotencia), auditoria, proveedores, cierres, correos_stock")
        Container(cli, "CLI de administración", "python -m ...", "Emite y revoca credenciales (app.usuarios.infrastructure.credenciales); respaldo y restauración (app.shared.infrastructure.respaldo)")
    }

    System_Ext(smtp, "Servidor SMTP", "Alertas de stock bajo")
    System_Ext(monitor, "Consumidor de métricas", "Prometheus u operador")

    Rel(usuario, app, "Usa")
    Rel(app, api, "Llama", "JSON / HTTPS + Authorization: Bearer")
    Rel(api, db, "Lee y escribe; una transacción por petición", "sqlite3")
    Rel(api, smtp, "Envía avisos de stock desde la cola", "SMTP + STARTTLS")
    Rel(cli, db, "Gestiona credenciales y copias", "sqlite3")
    Rel(monitor, api, "GET /metrics", "X-Internal-Token")
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
