# Nivel 1 · Diagrama de contexto

```mermaid
flowchart TB
    %%{init: {"flowchart": {"nodeSpacing": 70, "rankSpacing": 90, "curve": "basis", "htmlLabels": true}, "themeVariables": {"fontSize": "15px"}}}%%
    admin(["<b>Administrador</b><br/>Gestiona productos, proveedores,<br/>usuarios y cierres de turno"]):::person
    operador(["<b>Operador</b><br/>Registra entradas y salidas<br/>y toma cierres de turno"]):::person
    lector(["<b>Lector</b><br/>Consulta productos, stock,<br/>movimientos y cierres (solo lectura)"]):::person

    inventrack["<b>InvenTrack</b><br/>Sistema de inventarios para pequeñas empresas:<br/>productos, stock por SKU, movimientos,<br/>proveedores, usuarios y cierre de turno"]:::sys

    smtp["<b>Servidor SMTP</b><br/>Entrega el correo de alerta<br/>de stock bajo"]:::ext
    plataforma["<b>Plataforma de despliegue</b><br/>Dokploy institucional:<br/>ejecuta el contenedor y comprueba su salud"]:::ext
    monitor["<b>Consumidor de métricas y Swagger</b><br/>Acceso interno a /metrics,<br/>/docs y /openapi.json"]:::ext
    ci["<b>GitHub Actions y SonarCloud</b><br/>Pruebas, análisis estático,<br/>auditoría de dependencias y contrato OpenAPI"]:::ext

    admin -->|"App Flutter<br/>HTTPS + Bearer"| inventrack
    operador -->|"App Flutter<br/>HTTPS + Bearer"| inventrack
    lector -->|"App Flutter<br/>HTTPS + Bearer"| inventrack
    inventrack -->|"Alerta de stock bajo<br/>SMTP + STARTTLS"| smtp
    plataforma -->|"Despliega y verifica<br/>GET /health"| inventrack
    monitor -->|"Lee métricas y docs<br/>X-Internal-Token"| inventrack
    ci -->|"Verifica código y contrato<br/>pytest, flutter test, OpenAPI"| inventrack

    classDef person fill:#08427b,stroke:#052e56,color:#ffffff
    classDef sys fill:#1168bd,stroke:#0b4884,color:#ffffff
    classDef ext fill:#999999,stroke:#6b6b6b,color:#ffffff
    classDef cont fill:#438dd5,stroke:#2e6295,color:#ffffff
    classDef comp fill:#85bbf0,stroke:#5d82a8,color:#000000
    classDef db fill:#438dd5,stroke:#2e6295,color:#ffffff
```

## Actores y permisos (según `permitido()` en `app/usuarios/infrastructure/credenciales.py`)

| Rol | Lectura (GET) | Escritura |
|---|---|---|
| `admin` | Todo | Todo, incluida la administración de `/usuarios` |
| `operador` | Todo menos `/usuarios` | Solo `POST` en `/inventario` y `/cierres` |
| `lector` | Todo menos `/usuarios` | Nada |

## Notas

- En el perfil demo (sin `INVENTRACK_DB_PATH`) no hay autenticación y `/usuarios` responde 403.
- En producción, las rutas de negocio responden 503 hasta que existan base de datos y `INVENTRACK_ALLOW_BUSINESS_DATA=true`.
- El SMTP es opcional: sin `INVENTRACK_SMTP_HOST/DE/PARA` no se arranca el envío de correos.
