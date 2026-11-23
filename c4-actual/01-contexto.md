# Nivel 1 · Diagrama de contexto

```mermaid
C4Context
    title Contexto del sistema — InvenTrack

    Person(admin, "Administrador", "Gestiona productos, proveedores, usuarios y cierres de turno")
    Person(operador, "Operador", "Registra entradas y salidas de stock y toma cierres de turno")
    Person(lector, "Lector", "Consulta productos, stock, movimientos y cierres (solo lectura)")

    System(inventrack, "InvenTrack", "Sistema de inventarios para pequeñas empresas: productos, stock por SKU, movimientos, proveedores, usuarios y cierre/conciliación de turno")

    System_Ext(smtp, "Servidor SMTP", "Entrega el correo de alerta de stock bajo")
    System_Ext(plataforma, "Plataforma de despliegue", "Dokploy institucional (iscoutb.dev) y Render; ejecutan el contenedor y hacen health check")
    System_Ext(monitor, "Consumidor de métricas y Swagger", "Acceso interno con X-Internal-Token a /metrics, /docs y /openapi.json")
    System_Ext(ci, "GitHub Actions y SonarCloud", "Pruebas, análisis estático, auditoría de dependencias y validación del contrato OpenAPI")

    Rel(admin, inventrack, "Usa", "App Flutter / HTTPS + Bearer")
    Rel(operador, inventrack, "Usa", "App Flutter / HTTPS + Bearer")
    Rel(lector, inventrack, "Consulta", "App Flutter / HTTPS + Bearer")
    Rel(inventrack, smtp, "Envía alerta de stock bajo", "SMTP + STARTTLS")
    Rel(plataforma, inventrack, "Despliega y verifica", "GET /health")
    Rel(monitor, inventrack, "Lee métricas y documentación", "HTTPS + X-Internal-Token")
    Rel(ci, inventrack, "Verifica el código y el contrato", "pytest, flutter test, OpenAPI")
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
