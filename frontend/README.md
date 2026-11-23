# InvenTrack — Frontend (Flutter)

InvenTrack Frontend es una **aplicación cliente nativa multiplataforma** (móvil para Android e iOS, y escritorio para Windows), desarrollada en **Flutter** para interactuar con la API backend de **InvenTrack**.

> **Aclaración arquitectónica:** Este frontend es un **cliente nativo que se compila y ejecuta en el dispositivo del usuario**; **no es una aplicación web desplegada en servidor** ni un sitio web alojado independientemente. Toda su comunicación se realiza vía HTTP/HTTPS contra los endpoints expuestos por la API de InvenTrack, cumpliendo de forma estricta el contrato OpenAPI versionado [`contracts/openapi/v1.json`](../contracts/openapi/v1.json) sin extender ni alterar los endpoints del backend.

---

La acción **Gestión** de la pantalla principal abre el directorio de proveedores, el historial por SKU y los cierres de turno. Un administrador puede editar proveedores y administrar usuarios del perfil SQLite. Un operador puede tomar un corte y comparar el conteo físico en formato `sku,cantidad`. El lector puede consultar proveedores, movimientos y la lista de cortes. La primera credencial administrativa se emite desde la consola del servicio. [Configuración de la API](../README.md).

## Requisitos previos

- **Flutter SDK** `>= 3.41` y **Dart SDK** `>= 3.0.0 <4.0.0` (verificado con Flutter `3.41.6` / Dart `3.11.4`).
- Para ejecutar en **Android**: Android Studio, Android SDK y un emulador o dispositivo habilitado en `flutter doctor`.
- Para ejecutar en **iOS**: macOS con Xcode y un simulador o dispositivo iOS. Flutter no permite compilar iOS desde Windows.
- **Backend FastAPI** de InvenTrack en ejecución (por defecto en `http://localhost:8000`).

---

## Cómo ejecutar

### 1. Arrancar el backend (desde la raíz del repositorio)

```powershell
python -m uvicorn app.main:app --reload
```

### 2. Arrancar el frontend móvil (desde `frontend/`)

```powershell
flutter run -d android
```

> Si aún no se han descargado los paquetes en el entorno local, ejecutar previamente `flutter pub get`.

### Configurar otra URL de API

Por defecto (`lib/config/api_config.dart`), el cliente se conecta a `http://localhost:8000`. Puede indicarse otra URL en tiempo de compilación/ejecución mediante `--dart-define`:

```powershell
flutter run -d android --dart-define=INVENTRACK_API_URL=http://10.0.2.2:8000
```

Para apuntar directamente al backend institucional en Dokploy:

```powershell
flutter run -d android --dart-define=INVENTRACK_API_URL=https://inventrack.iscoutb.dev
# o en Windows:
flutter run -d windows --dart-define=INVENTRACK_API_URL=https://inventrack.iscoutb.dev
```

> **Acceso en Dokploy.** Para probar catálogo e inventario en la instancia institucional, añade `--dart-define=INVENTRACK_AUTH=true` al comando y usa una credencial individual de ensayo. El 22/11/2026 las consultas anónimas devolvieron 401. En un entorno con `INVENTRACK_ALLOW_BUSINESS_DATA=false`, el negocio devuelve 503. [Verificación institucional](../docs/verificacion-final.md#verificación-pública-y-colaboración).
>
> **Conexión desde móvil:** En el emulador Android, `10.0.2.2` apunta al `localhost` de la máquina anfitriona. En un dispositivo físico se debe usar la IP local del equipo que ejecuta el backend, por ejemplo `http://192.168.1.10:8000`, y permitir el tráfico correspondiente en la red.
>
> **iOS:** Ejecuta `flutter run -d ios` desde macOS con Xcode configurado. Para el simulador iOS normalmente se puede usar `http://127.0.0.1:8000`; un dispositivo físico debe usar la IP local del equipo que ejecuta el backend.
>
> El proyecto conserva el runner `windows/` existente, pero la plataforma objetivo del producto es ahora móvil mediante `android/` e `ios/`.

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

### Catálogo y acceso

Al abrir **Gestión**, Flutter consulta `GET /sesion` para mostrar las acciones del rol actual.

| Sección | Operaciones del cliente |
|---|---|
| Proveedores | `GET /proveedores` lista el directorio. El administrador crea con `POST /proveedores` y edita o elimina con `PUT` o `DELETE /proveedores/{id}`. |
| Historial por producto | `GET /inventario/{producto_id}/movimientos` muestra las entradas y salidas más recientes primero, con cantidad, fecha y actor en el perfil durable. |
| Cierre de turno | `GET /cierres` lista los cortes. El operador o administrador toma uno con `POST /cierres` y compara su CSV mediante `POST /cierres/{id}/conciliar`. |
| Usuarios | El administrador lista y crea cuentas en `/usuarios`, cambia roles, rota credenciales y revoca accesos. La credencial nueva se muestra al emitirla. |

La tarjeta de existencias indica **Stock bajo** entre 1 y 10 unidades. El backend encola un correo cuando una salida cruza de más de 10 unidades a 10 o menos. Su entrega requiere SMTP en el perfil SQLite. [Configuración del correo](../README.md#despliegue-en-iscoutbdev).

La pestaña Productos sincroniza el catálogo mediante `GET /productos`. Para el perfil durable se activa `--dart-define=INVENTRACK_AUTH=true` y se introduce la credencial en la pantalla inicial. El cliente admite credenciales por HTTPS o por HTTP en loopback. Los permisos los valida la API.

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
