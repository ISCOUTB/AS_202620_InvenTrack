# InvenTrack — Frontend (Flutter)

Cliente gráfico multiplataforma (configurado inicialmente para escritorio **Windows**) desarrollado en **Flutter** para **InvenTrack**. Consume estrictamente la API HTTP definida en el contrato versionado [`contracts/openapi/v1.json`](../contracts/openapi/v1.json) sin añadir ni modificar endpoints del backend.

---

## Requisitos previos

- **Flutter SDK** `>= 3.41` y **Dart SDK** `>= 3.0.0 <4.0.0` (verificado con Flutter `3.41.6` / Dart `3.11.4`).
- Para ejecutar en **Windows Desktop**: herramientas de compilación C++ de Visual Studio (*Desktop development with C++*) habilitadas en `flutter doctor`.
- **Backend FastAPI** de InvenTrack en ejecución (por defecto en `http://localhost:8000`).

---

## Cómo ejecutar

### 1. Arrancar el backend (desde la raíz del repositorio)

```powershell
python -m uvicorn app.main:app --reload
```

### 2. Arrancar el frontend en un solo comando (desde `frontend/`)

```powershell
flutter run -d windows
```

> Si aún no se han descargado los paquetes en el entorno local, ejecutar previamente `flutter pub get`.

### Configurar otra URL de API

Por defecto (`lib/config/api_config.dart`), el cliente se conecta a `http://localhost:8000`. Puede indicarse otra URL en tiempo de compilación/ejecución mediante `--dart-define`:

```powershell
flutter run -d windows --dart-define=INVENTRACK_API_URL=http://127.0.0.1:8000
```

> **Nota sobre entornos desplegados:** En Dokploy (`https://inventrack.iscoutb.dev`) y Render (`https://inventrack-api.onrender.com`), las rutas de negocio (`/productos`, `/inventario`) devuelven `503` mientras `INVENTRACK_ALLOW_BUSINESS_DATA=false` por política preventiva (únicamente `/health` responde `200`). Para probar los flujos completos de catálogo e inventario, ejecuta contra el backend local.
>
> **Otras plataformas:** Actualmente solo está generada la carpeta nativa `windows/`. Para habilitar Web, Android, Linux o macOS se requiere `flutter create --platforms=<plataforma> .` (y en el caso de Flutter Web, habilitar CORS en desarrollo en el backend).

---

## Cómo probar y verificar

Desde la carpeta `frontend/`:

```powershell
# Análisis estático (linting y tipos)
flutter analyze

# Pruebas unitarias y de widgets (usan MockClient; no requieren backend levantado)
flutter test
```

---

## Operaciones del contrato OpenAPI v1 soportadas

| Vista / Acción en UI | Método y Endpoint | Respuestas manejadas | Notas de contrato |
|---|---|---|---|
| Indicador de estado en `AppBar` | `GET /health` | `200 OK` | Verifica disponibilidad del servicio al iniciar y permite reverificar al tocar el indicador. |
| **Productos** → Crear producto | `POST /productos` | `201 Created`, `422` | Envía `{"id", "nombre"}` y muestra el `ProductoResponse` (`activo: true`). |
| **Productos** → Eliminar / desactivar | `DELETE /productos/{producto_id}` | `200 OK`, `404` | Refleja borrado físico o desactivación lógica (**ESC-02**) según `eliminado_fisicamente` / `desactivado`. |
| **Inventario** → Consultar stock | `GET /inventario/{producto_id}` | `200 OK`, `404` | Muestra el stock actual con indicador visual por nivel. |
| **Inventario** → Registrar entrada | `POST /inventario/{producto_id}/entradas` | `200 OK`, `400`, `404`, `409`, `422`, `503` | Valida `cantidad > 0` y envía `X-Correlation-ID` y `X-Idempotency-Key` técnicos sin PII (**ADR-0017**). |
| **Inventario** → Registrar salida | `POST /inventario/{producto_id}/salidas` | `200 OK`, `400`, `404`, `409`, `422`, `503` | Maneja `409 Conflict` ante stock insuficiente o conflicto de idempotencia y `503` ante timeout de lock. |

### Límites conocidos del MVP en el cliente

- El contrato `contracts/openapi/v1.json` no expone `GET /productos`; por ello la pestaña **Productos** conserva en memoria los productos creados durante la sesión actual, mientras que en **Inventario** puede consultarse u operarse cualquier `producto_id` existente en el backend.
- El módulo `usuarios` no está implementado en el MVP, por lo que el cliente opera sin autenticación.

---

## Estructura de carpetas

```text
frontend/
├── lib/
│   ├── main.dart                         # Punto de entrada y MultiProvider (Material 3)
│   ├── config/
│   │   └── api_config.dart               # URL base (INVENTRACK_API_URL) y timeout HTTP
│   ├── models/
│   │   ├── producto.dart                 # Producto, CrearProductoRequest, EliminarProductoResponse
│   │   ├── movimiento.dart               # MovimientoRequest (cantidad > 0), MovimientoResponse
│   │   └── stock.dart                    # Stock
│   ├── services/
│   │   ├── api_service.dart              # Cliente HTTP tipado para OpenAPI v1
│   │   └── api_exception.dart            # Mapeo de errores HTTP (400, 404, 409, 422, 500, 503)
│   ├── providers/
│   │   ├── health_provider.dart          # Estado de salud del backend
│   │   ├── productos_provider.dart       # Estado local de productos sincronizado con API
│   │   └── inventario_provider.dart      # Stock actual, caché y movimientos recientes
│   ├── screens/
│   │   ├── home_page.dart                # Navegación Productos / Inventario e indicador /health
│   │   ├── productos_page.dart           # Alta y borrado físico/lógico (ESC-02)
│   │   └── inventario_page.dart          # Consulta de stock y registro de entradas/salidas
│   └── widgets/
│       ├── crear_producto_dialog.dart    # Diálogo de creación de producto
│       ├── movimiento_dialog.dart        # Diálogo de entrada/salida con validación > 0
│       ├── stock_card.dart               # Tarjeta visual de stock por nivel
│       └── movimiento_card.dart          # Tarjeta de resultado/historial reciente
└── test/
    ├── api_service_test.dart             # Pruebas contractuales del cliente HTTP con MockClient
    └── widget_test.dart                  # Prueba de flujo UI Productos -> Inventario
```
