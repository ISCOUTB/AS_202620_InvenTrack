# ADR-0019: Autenticar a cada usuario con una credencial revocable y autorizar por rol

- **Estado:** Aceptado
- **Fecha:** 2026-11-19
- **Decisores:** Equipo InvenTrack
- **Reemplaza:** El bloqueo incondicional de negocio de [ADR-0018](0018-restringir-superficies-internas-en-produccion.md) en el perfil durable. Se conserva el token operativo para métricas y documentación.

## Contexto y alternativas

ESC-05 requiere identificar al actor y distinguir permisos insuficientes de credenciales inválidas. Compartir una clave entre empleados impediría revocar un solo acceso y atribuir movimientos. OIDC aporta delegación y SSO con la dependencia operativa de un proveedor. Para una PYME de una instancia se eligen credenciales aleatorias individuales emitidas por el administrador del despliegue.

## Decisión y consecuencias

Generar 32 bytes aleatorios por usuario. Almacenar únicamente el digest SHA-256, un identificador técnico estable y un rol. Rotar mediante reemisión y revocar por CLI. Exigir transporte TLS fuera de localhost. El lector consulta catálogo y stock. El operador también registra movimientos. El administrador además crea y elimina productos. La administración de identidades queda fuera de HTTP. La cabecera de autorización se valida en cada petición y el actor proviene de la identidad resuelta en el servidor. El cliente conserva el secreto solo durante la sesión.

El perfil durable siempre requiere identidad. Producción además exige habilitación explícita y una base configurada. El token interno solo permite superficies operativas. La gestión manual implica distribución individual, revocación por pérdida y prohibición de reasignar identificadores. La federación, MFA y caducidad automática quedan pendientes para una operación mayor.

## Trazabilidad

[ESC-05 y §8](../arc42/arc42-template-EN.md#quality-scenarios), [C4 de componentes](../c4/components.md), [emisión y permisos](../../app/usuarios/infrastructure/credenciales.py), [middleware](../../app/main.py), [pruebas de autorización y rotación](../../tests/test_perfil_durable.py). Cambio posterior a la revisión 95baaf0, pendiente de integración.
