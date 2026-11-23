# ADR-0023: Administrar identidades desde Flutter

- **Estado:** Aceptado
- **Fecha:** 2026-11-22
- **Decisores:** Equipo InvenTrack
- **Reemplaza:** La restricción de [ADR-0019](0019-autenticar-usuarios-y-autorizar-por-rol.md) que excluye la administración de identidades por HTTP. Se conservan las credenciales individuales, los roles y la validación de permisos en cada petición.

## Contexto y alternativas

El ADR-0019 concentró la emisión y revocación de credenciales en la consola del servicio. El administrador de una tienda necesita dar acceso a otro operador desde la aplicación sin tener acceso al contenedor. Mantener la consola como único canal exigiría la intervención de quien opera el despliegue por cada cambio de personal.

## Decisión

La consola permite crear la primera cuenta administradora y recuperar el acceso. La API autenticada del perfil SQLite permite al administrador listar cuentas, emitir credenciales individuales, cambiar roles, rotar credenciales y revocar accesos. Flutter consulta el rol en `/sesion` y muestra **Gestión → Usuarios** al administrador. El servidor verifica el rol en cada solicitud. El token nuevo se entrega al emitirlo, con `Cache-Control: no-store`. SQLite guarda su digest.

## Consecuencias y reversión

El cambio de rol y la revocación se aplican desde la petición siguiente. Para revocar la propia cuenta, reducir su rol o rotar su credencial desde Flutter se necesita otra cuenta administradora. La consola conserva su mecanismo de recuperación. Si se retira el router de administración y su sección en Flutter, las credenciales ya emitidas conservan su validez.

## Trazabilidad

[Router de usuarios](../../app/usuarios/infrastructure/router.py) · [contrato HTTP](../api/inventrack-contrato.md) · [verificación de roles y rotación](../../tests/test_gestion_integrada.py).
