# ADR-0018: Restringir métricas y documentación en producción con un token operativo

- **Estado:** Aceptado
- **Fecha:** 2026-11-19
- **Decisores:** Equipo InvenTrack
- **Alcance:** MVP cerrado, posterior a S15.
- **Decisión sucesora:** [ADR-0019](0019-autenticar-usuarios-y-autorizar-por-rol.md) para el acceso individual en el perfil durable.

## Contexto y opciones

Operaciones necesita verificar la salud de la instancia y diagnosticar latencias. Publicar métricas y esquemas expone rutas y actividad. Ocultar todo impediría el diagnóstico remoto. Un proveedor de identidad permitiría identificar a cada operador y revocar permisos individuales, pero requiere gestionar usuarios y roles fuera del alcance actual.

## Decisión

Mantener pública la sonda mínima `/health`. En producción, exigir `X-Internal-Token` para métricas, Swagger, su redirección OAuth, ReDoc y OpenAPI. El proveedor inyecta el secreto en `INVENTRACK_INTERNAL_TOKEN`. Ante secreto ausente o incorrecto se devuelve 404. Las rutas de productos e inventario responden 503 incluso si se presenta el token operativo. El cliente Flutter nunca recibe este secreto.

## Consecuencias

Operaciones rota el secreto en el proveedor y reinicia el servicio, ya que FastAPI configura las rutas de documentación al arrancar. El token compartido limita la atribución individual. Habilitar negocio requiere una decisión sucesora sobre identidad, permisos y actor de auditoría, además de verificar recuperación de datos conforme a ADR-0015.

## Trazabilidad

Las amenazas T-01 y T-06 se describen en la [evidencia de seguridad](../evidencia-seguridad-s13.md). El control se ubica a la entrada del [backend C4](../c4/components.md) y se introdujo en el [commit 1d667d1](https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/1d667d1). La [política HTTP](../../app/main.py) y las [pruebas de acceso](../../tests/test_health.py) fijan el alcance actual.
