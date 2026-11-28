# Nivel 3 · Diagramas de componentes

## 3.1 API: middleware, composition root y módulos

```mermaid
flowchart TB
    %%{init: {"flowchart": {"nodeSpacing": 70, "rankSpacing": 90, "curve": "basis", "htmlLabels": true}, "themeVariables": {"fontSize": "15px"}}}%%
    app["<b>Cliente Flutter</b><br/>Dart"]:::ext
    db[("<b>Base SQLite</b><br/>WAL")]:::db
    smtp["<b>Servidor SMTP</b>"]:::ext

    subgraph api ["API InvenTrack (FastAPI)"]
        direction TB
        obs["<b>ObservabilityMiddleware</b><br/>Cuenta peticiones, calcula p95,<br/>escribe logs JSON"]:::comp
        acceso["<b>AccessPolicyMiddleware</b><br/>Oculta superficies internas, aplica perfil (503/403),<br/>autentica, autoriza por rol y abre la transacción"]:::comp
        root["<b>Composition root</b> (app/main.py)<br/>Construye repositorios, casos de uso y adaptadores<br/>/health y /metrics (ADR-0003)"]:::comp
        usuarios["<b>Módulo usuarios</b><br/>Sesión, administración<br/>y tokens"]:::comp
        productos["<b>Módulo productos</b><br/>Alta, consulta y baja"]:::comp
        inventario["<b>Módulo inventario</b><br/>Entradas, salidas, stock, movimientos,<br/>idempotencia, cierres y conciliación"]:::comp
        proveedores["<b>Módulo proveedores</b><br/>CRUD de proveedores"]:::comp
        alertas["<b>Módulo alertas</b><br/>Cruce de umbral de stock<br/>y envío de correos"]:::comp
        mensajeria["<b>Broker simulado</b> (app/messaging)<br/>Reintentos, backoff, deduplicación y DLQ"]:::comp
        shared["<b>Núcleo compartido SQLite</b> (app/shared)<br/>Conexión por petición, lock de escritura,<br/>esquema, actor y respaldo"]:::comp
    end

    app -->|"HTTPS + Bearer"| obs
    obs -->|"Pasa la petición"| acceso
    acceso -->|"Autentica"| usuarios
    acceso -->|"Delega tras autorizar"| productos
    acceso -->|"Delega tras autorizar"| inventario
    acceso -->|"Delega tras autorizar"| proveedores
    acceso -->|"Abre transacción<br/>y fija el actor"| shared
    root -.->|"Ensambla"| productos
    root -.->|"Ensambla"| inventario
    inventario -->|"Valida producto<br/>(puertos ADR-0003)"| productos
    inventario -->|"Solo demo en memoria"| mensajeria
    inventario -->|"Registra cruce<br/>de umbral"| alertas
    productos -->|"Persiste"| shared
    inventario -->|"Persiste"| shared
    proveedores -->|"Persiste"| shared
    usuarios -->|"Persiste"| shared
    alertas -->|"Lee y actualiza<br/>correos_stock"| shared
    shared -->|"sqlite3"| db
    alertas -->|"SMTP + STARTTLS"| smtp

    classDef person fill:#08427b,stroke:#052e56,color:#ffffff
    classDef sys fill:#1168bd,stroke:#0b4884,color:#ffffff
    classDef ext fill:#999999,stroke:#6b6b6b,color:#ffffff
    classDef cont fill:#438dd5,stroke:#2e6295,color:#ffffff
    classDef comp fill:#85bbf0,stroke:#5d82a8,color:#000000
    classDef db fill:#438dd5,stroke:#2e6295,color:#ffffff
```

## 3.2 Módulo inventario

```mermaid
flowchart TB
    %%{init: {"flowchart": {"nodeSpacing": 70, "rankSpacing": 90, "curve": "basis", "htmlLabels": true}, "themeVariables": {"fontSize": "15px"}}}%%
    subgraph inv ["app/inventario"]
        direction TB
        rtr["<b>Router de inventario</b><br/>POST entradas y salidas,<br/>GET /inventario/id"]:::comp
        cierres["<b>Router de cierres</b><br/>POST y GET /cierres,<br/>POST /cierres/id/conciliar"]:::comp
        conc["<b>Conciliación</b><br/>Compara saldos contra<br/>el conteo físico (CSV)"]:::comp
        reg["<b>RegistrarMovimientoInventario</b><br/>Valida producto, aplica entrada o salida,<br/>impide stock negativo"]:::comp
        hist["<b>ConsultarHistorialMovimientos</b><br/>Lista movimientos por producto"]:::comp
        dom["<b>Dominio</b><br/>Stock, Movimiento, excepciones<br/>y puertos"]:::comp
        idem["<b>Idempotencia</b><br/>Clave + huella por actor"]:::comp
        repo["<b>Repositorios</b><br/>InMemory (demo) o SQLite"]:::comp
        val["<b>ValidadorDeProductoAdapter</b><br/>Adaptador del puerto hacia productos"]:::comp
    end

    prod["<b>Módulo productos</b><br/>ConsultarProducto"]:::ext
    broker["<b>Broker simulado</b><br/>publicar()"]:::ext
    alert["<b>Módulo alertas</b><br/>registrar_cruce()"]:::ext
    db[("<b>Base SQLite</b>")]:::db

    rtr -->|"Invoca"| reg
    rtr -->|"Reserva clave"| idem
    rtr -->|"Demo · publicación en segundo plano"| broker
    rtr -->|"SQLite · auditoría transaccional"| repo
    rtr -->|"Registra cruce<br/>de umbral"| alert
    reg -->|"Usa"| dom
    reg -->|"Valida producto"| val
    reg -->|"Guarda stock<br/>y movimiento"| repo
    hist -->|"Lee movimientos"| repo
    val -->|"Consulta"| prod
    cierres -->|"Compara"| conc
    cierres -->|"Lee stock"| repo
    repo -->|"SQL"| db

    classDef person fill:#08427b,stroke:#052e56,color:#ffffff
    classDef sys fill:#1168bd,stroke:#0b4884,color:#ffffff
    classDef ext fill:#999999,stroke:#6b6b6b,color:#ffffff
    classDef cont fill:#438dd5,stroke:#2e6295,color:#ffffff
    classDef comp fill:#85bbf0,stroke:#5d82a8,color:#000000
    classDef db fill:#438dd5,stroke:#2e6295,color:#ffffff
```

## 3.3 Módulos productos, usuarios, proveedores y alertas

```mermaid
flowchart TB
    %%{init: {"flowchart": {"nodeSpacing": 70, "rankSpacing": 90, "curve": "basis", "htmlLabels": true}, "themeVariables": {"fontSize": "15px"}}}%%
    db[("<b>Base SQLite</b>")]:::db
    smtp["<b>Servidor SMTP</b>"]:::ext
    inv["<b>Módulo inventario</b><br/>MovimientoRepository"]:::ext

    subgraph p ["app/productos"]
        direction TB
        prouter["<b>Router de productos</b><br/>GET y POST /productos,<br/>DELETE /productos/id"]:::comp
        pcu["<b>Casos de uso</b><br/>Crear, Consultar y Eliminar producto"]:::comp
        prepo["<b>Repositorios de producto</b><br/>InMemory o ProductosSQLite"]:::comp
        phist["<b>HistorialMovimientosAdapter</b><br/>Impide eliminar un producto<br/>con movimientos"]:::comp
    end
    subgraph u ["app/usuarios"]
        direction TB
        urouter["<b>Router de usuarios</b><br/>/sesion y /usuarios<br/>(rotar, rol, eliminar)"]:::comp
        cred["<b>credenciales</b><br/>emitir, autenticar (SHA-256),<br/>permitido (rol/método/ruta), CLI"]:::comp
    end
    subgraph v ["app/proveedores"]
        vrouter["<b>Router de proveedores</b><br/>GET, POST, PUT y DELETE"]:::comp
    end
    subgraph a ["app/alertas"]
        correo["<b>correo.py</b><br/>registrar_cruce (umbral 10), cola correos_stock,<br/>despacho con backoff y envío SMTP"]:::comp
    end

    prouter -->|"Invoca"| pcu
    pcu -->|"Usa"| prepo
    pcu -->|"Verifica movimientos"| phist
    phist -->|"Consulta historial"| inv
    prepo -->|"SQL"| db
    urouter -->|"Usa"| cred
    cred -->|"SQL"| db
    vrouter -->|"SQL"| db
    correo -->|"SQL"| db
    correo -->|"SMTP + STARTTLS"| smtp

    classDef person fill:#08427b,stroke:#052e56,color:#ffffff
    classDef sys fill:#1168bd,stroke:#0b4884,color:#ffffff
    classDef ext fill:#999999,stroke:#6b6b6b,color:#ffffff
    classDef cont fill:#438dd5,stroke:#2e6295,color:#ffffff
    classDef comp fill:#85bbf0,stroke:#5d82a8,color:#000000
    classDef db fill:#438dd5,stroke:#2e6295,color:#ffffff
```

## 3.4 Cliente Flutter

```mermaid
flowchart TB
    %%{init: {"flowchart": {"nodeSpacing": 70, "rankSpacing": 90, "curve": "basis", "htmlLabels": true}, "themeVariables": {"fontSize": "15px"}}}%%
    api["<b>API InvenTrack</b><br/>FastAPI"]:::ext

    subgraph f ["frontend/lib"]
        direction TB
        screens["<b>screens</b><br/>home, productos, inventario<br/>y gestión"]:::comp
        widgets["<b>widgets y ui</b><br/>stock_card, movimiento_card,<br/>diálogos e inventrack_style"]:::comp
        prov["<b>providers</b> (ChangeNotifier)<br/>health, productos e inventario"]:::comp
        svc["<b>services/api_service.dart</b><br/>Único acceso HTTP: https salvo localhost,<br/>añade Bearer y traduce errores a ApiException"]:::comp
        models["<b>models</b><br/>Producto, Stock, Movimiento"]:::comp
        cfg["<b>config/api_config.dart</b><br/>INVENTRACK_API_URL<br/>e INVENTRACK_AUTH"]:::comp
    end

    screens -->|"Compone"| widgets
    screens -->|"Observa y dispara acciones"| prov
    prov -->|"Usa"| svc
    svc -->|"Serializa"| models
    svc -->|"Lee URL base"| cfg
    svc -->|"JSON / HTTPS"| api

    classDef person fill:#08427b,stroke:#052e56,color:#ffffff
    classDef sys fill:#1168bd,stroke:#0b4884,color:#ffffff
    classDef ext fill:#999999,stroke:#6b6b6b,color:#ffffff
    classDef cont fill:#438dd5,stroke:#2e6295,color:#ffffff
    classDef comp fill:#85bbf0,stroke:#5d82a8,color:#000000
    classDef db fill:#438dd5,stroke:#2e6295,color:#ffffff
```
