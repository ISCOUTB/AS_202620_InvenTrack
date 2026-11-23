# Nivel 3 · Diagramas de componentes

## 3.1 API: middleware, composition root y módulos

```mermaid
C4Component
    title Componentes — API InvenTrack (vista general)

    Container_Ext(app, "Cliente Flutter", "Dart")
    ContainerDb_Ext(db, "Base SQLite", "WAL")
    System_Ext(smtp, "Servidor SMTP")

    Container_Boundary(api, "API InvenTrack (FastAPI)") {
        Component(obs, "ObservabilityMiddleware", "Starlette middleware", "Cuenta peticiones, acumula duraciones, calcula p95 y escribe logs JSON")
        Component(acceso, "AccessPolicyMiddleware", "Starlette middleware", "Oculta superficies internas en producción, aplica el perfil (503/403), autentica, autoriza por rol y abre la transacción por petición")
        Component(root, "Composition root", "app/main.py", "Construye repositorios, casos de uso y adaptadores; conecta los módulos (ADR-0003); /health, /metrics")
        Component(usuarios, "Módulo usuarios", "Router + credenciales", "Sesión y administración de usuarios; emisión, rotación y revocación de tokens")
        Component(productos, "Módulo productos", "Hexagonal", "Alta, consulta y baja de productos")
        Component(inventario, "Módulo inventario", "Hexagonal", "Entradas, salidas, stock, movimientos, idempotencia, cierres y conciliación")
        Component(proveedores, "Módulo proveedores", "Router", "CRUD de proveedores")
        Component(alertas, "Módulo alertas", "Infraestructura", "Detecta cruce del umbral de stock y envía correos desde la cola")
        Component(mensajeria, "Broker simulado", "app/messaging", "Publicación en proceso con reintentos, backoff exponencial, deduplicación y DLQ")
        Component(shared, "Núcleo compartido SQLite", "app/shared", "Conexión por petición (ContextVar), lock de escritura, esquema, actor, respaldo")
    }

    Rel(app, obs, "HTTPS + Bearer")
    Rel(obs, acceso, "Pasa la petición")
    Rel(acceso, shared, "Abre transacción y fija el actor")
    Rel(acceso, usuarios, "Autentica con la tabla usuarios")
    Rel(acceso, productos, "Delega tras autorizar")
    Rel(acceso, inventario, "Delega tras autorizar")
    Rel(acceso, proveedores, "Delega tras autorizar")
    Rel(root, productos, "Ensambla")
    Rel(root, inventario, "Ensambla")
    Rel(inventario, productos, "Valida producto activo e historial", "puertos ADR-0003")
    Rel(inventario, mensajeria, "Publica MovimientoDeInventarioRegistrado")
    Rel(inventario, alertas, "Registra cruce de umbral")
    Rel(productos, shared, "Persiste")
    Rel(inventario, shared, "Persiste")
    Rel(proveedores, shared, "Persiste")
    Rel(usuarios, shared, "Persiste")
    Rel(alertas, shared, "Lee y actualiza correos_stock")
    Rel(shared, db, "sqlite3")
    Rel(alertas, smtp, "SMTP + STARTTLS")
```

## 3.2 Módulo inventario

```mermaid
C4Component
    title Componentes — módulo inventario

    Container_Boundary(inv, "app/inventario") {
        Component(rtr, "Router de inventario", "FastAPI APIRouter", "POST /inventario/{id}/entradas, POST /inventario/{id}/salidas, GET /inventario/{id}")
        Component(cierres, "Router de cierres", "FastAPI APIRouter", "POST /cierres, GET /cierres, POST /cierres/{id}/conciliar")
        Component(conc, "Conciliación", "application", "interpretar_csv (sku,cantidad) y comparar saldos contra el conteo físico")
        Component(reg, "RegistrarMovimientoInventario", "application", "Caso de uso: valida producto, aplica entrada o salida, impide stock negativo, registra el movimiento")
        Component(hist, "ConsultarHistorialMovimientos", "application", "Lista movimientos por producto")
        Component(dom, "Dominio", "domain", "Stock, Movimiento, excepciones, puertos StockRepository, MovimientoRepository y ValidadorDeProducto")
        Component(idem, "Idempotencia", "infrastructure", "Clave + huella por actor; en memoria o tabla comandos")
        Component(repo, "Repositorios", "infrastructure", "InMemory (demo) o SQLite: StockSQLite, MovimientosSQLite, IdempotenciaSQLite, guardar_evento")
        Component(val, "ValidadorDeProductoAdapter", "infrastructure", "Adaptador del puerto hacia ConsultarProducto (módulo productos)")
    }

    Component_Ext(prod, "Módulo productos", "ConsultarProducto, ProductoRepository")
    Component_Ext(broker, "Broker simulado", "publicar()")
    Component_Ext(alert, "Módulo alertas", "registrar_cruce()")
    ContainerDb_Ext(db, "Base SQLite")

    Rel(rtr, reg, "Invoca")
    Rel(rtr, idem, "Reserva clave de idempotencia")
    Rel(rtr, broker, "Publica evento en segundo plano")
    Rel(rtr, repo, "Guarda evento de auditoría")
    Rel(rtr, alert, "Registra cruce de umbral")
    Rel(reg, dom, "Usa")
    Rel(reg, val, "Valida producto", "puerto")
    Rel(reg, repo, "Guarda stock y movimiento", "puertos")
    Rel(hist, repo, "Lee movimientos")
    Rel(val, prod, "Consulta")
    Rel(cierres, conc, "Compara")
    Rel(cierres, repo, "Lee stock")
    Rel(repo, db, "SQL")
```

## 3.3 Módulos productos, usuarios, proveedores y alertas

```mermaid
C4Component
    title Componentes — productos, usuarios, proveedores y alertas

    Container_Boundary(p, "app/productos") {
        Component(prouter, "Router de productos", "FastAPI", "GET y POST /productos, DELETE /productos/{id}")
        Component(pcu, "Casos de uso", "application", "CrearProducto, ConsultarProducto, EliminarProducto")
        Component(prepo, "Repositorios de producto", "infrastructure", "InMemoryProductoRepository o ProductosSQLite")
        Component(phist, "HistorialMovimientosAdapter", "infrastructure", "Impide eliminar un producto con movimientos (consulta a inventario)")
    }
    Container_Boundary(u, "app/usuarios") {
        Component(urouter, "Router de usuarios", "FastAPI", "GET /sesion, GET y POST /usuarios, POST /usuarios/{id}/rotar, PUT /usuarios/{id}/rol, DELETE /usuarios/{id}")
        Component(cred, "credenciales", "infrastructure", "emitir, autenticar (SHA-256 del token), permitido (matriz rol/método/ruta) y CLI emitir/revocar")
    }
    Container_Boundary(v, "app/proveedores") {
        Component(vrouter, "Router de proveedores", "FastAPI", "GET y POST /proveedores, PUT y DELETE /proveedores/{id}")
    }
    Container_Boundary(a, "app/alertas") {
        Component(correo, "correo.py", "infrastructure", "registrar_cruce (umbral 10), cola correos_stock, despachar_uno con backoff, procesar_cola asyncio, envío SMTP")
    }

    ContainerDb_Ext(db, "Base SQLite")
    System_Ext(smtp, "Servidor SMTP")
    Component_Ext(inv, "Módulo inventario", "MovimientoRepository")

    Rel(prouter, pcu, "Invoca")
    Rel(pcu, prepo, "Usa")
    Rel(pcu, phist, "Verifica movimientos")
    Rel(phist, inv, "Consulta historial")
    Rel(prepo, db, "SQL")
    Rel(urouter, cred, "Usa")
    Rel(cred, db, "SQL")
    Rel(vrouter, db, "SQL")
    Rel(correo, db, "SQL")
    Rel(correo, smtp, "SMTP + STARTTLS")
```

## 3.4 Cliente Flutter

```mermaid
C4Component
    title Componentes — Cliente Flutter

    Container_Boundary(f, "frontend/lib") {
        Component(screens, "screens", "Widgets de página", "home_page, productos_page, inventario_page, gestion_page")
        Component(widgets, "widgets y ui", "Widgets reutilizables", "stock_card, movimiento_card, diálogos de producto y movimiento, inventrack_style")
        Component(prov, "providers", "provider (ChangeNotifier)", "health_provider, productos_provider, inventario_provider")
        Component(svc, "services/api_service.dart", "http.Client", "Único punto de acceso HTTP: exige https salvo localhost, añade Bearer y traduce errores a ApiException")
        Component(models, "models", "Dart", "Producto, Stock, Movimiento")
        Component(cfg, "config/api_config.dart", "dart-define", "INVENTRACK_API_URL e INVENTRACK_AUTH")
    }
    Container_Ext(api, "API InvenTrack", "FastAPI")

    Rel(screens, widgets, "Compone")
    Rel(screens, prov, "Observa y dispara acciones")
    Rel(prov, svc, "Usa")
    Rel(svc, models, "Serializa")
    Rel(svc, cfg, "Lee URL base")
    Rel(svc, api, "JSON / HTTPS")
```
