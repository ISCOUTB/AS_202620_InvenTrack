# C4 actual de InvenTrack

Modelo C4 reconstruido a partir del código vigente (`app/`, `frontend/`, `deploy/`, `render.yaml`, `Dockerfile`, `.github/`).
No se basa en `docs/c4/`. Los diagramas usan Mermaid (se visualizan en GitHub y en VS Code con una extensión Mermaid).

| Nivel | Archivo | Qué responde |
|---|---|---|
| 1 · Contexto | [01-contexto.md](01-contexto.md) | Quién usa el sistema y con qué sistemas externos habla |
| 2 · Contenedores | [02-contenedores.md](02-contenedores.md) | Qué se despliega y cómo se comunica |
| 3 · Componentes | [03-componentes.md](03-componentes.md) | Cómo está organizada la API por dentro |
| Complementario · Despliegue | [04-despliegue.md](04-despliegue.md) | Dónde corre cada contenedor (Dokploy, Render, CI) |
| Complementario · Dinámico | [05-flujos.md](05-flujos.md) | Secuencias clave: salida de stock, cierre/conciliación, alerta por correo, acceso |

## Hechos del código en los que se apoya

- Un único proceso FastAPI (`app/main.py`) hace de *composition root*: monolito modular, hexagonal por módulo.
- Dos perfiles según `INVENTRACK_DB_PATH`: **demo en memoria** (sin autenticación) o **durable** (SQLite + Bearer + roles).
- Autenticación por token individual: se guarda el SHA-256 en la tabla `usuarios`. Roles `admin`, `operador`, `lector` (`credenciales.py:permitido`).
- Una conexión y una transacción SQLite por petición; escrituras serializadas con un lock anyio (espera máxima 5 s, luego 503 con `Retry-After`).
- Alertas de stock bajo: cola transaccional en la tabla `correos_stock`, consumida por una tarea asyncio que envía por SMTP con STARTTLS.
- El broker de mensajería es un **simulador en proceso** (reintentos, backoff, deduplicación, DLQ); no hay broker externo.
- Cliente Flutter (`frontend/`) con `provider` y `http`; apunta a la API con `INVENTRACK_API_URL`.
