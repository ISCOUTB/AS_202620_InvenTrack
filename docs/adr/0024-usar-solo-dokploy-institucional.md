# ADR-0024: Usar el servidor institucional como único destino de despliegue

- **Estado:** Aceptado
- **Fecha:** 2026-11-22
- **Decisores:** Equipo InvenTrack
- **Reemplaza:** La selección de plataforma de [ADR-0005](0005-eleccion-plataforma-despliegue.md) y la operación en paralelo contemplada por [ADR-0006](0006-desplegar-en-dokploy-institucional.md).

## Decisión y consecuencias

El equipo concentra la operación de InvenTrack en el servicio `sistema` de Dokploy. La API se publica en `inventrack.iscoutb.dev` y utiliza el volumen SQLite montado en `/app/data`. Un solo dominio, un volumen y un conjunto de credenciales permiten identificar la instancia que atendió cada ensayo. El cliente Flutter se ejecuta en el dispositivo del usuario.

La disponibilidad pública depende del servidor institucional. Para recuperar los datos tras perder el host se necesita una copia externa del volumen o de la base SQLite. El ensayo con la copia en el PC verificó el saldo recuperado en 1,738 s. [Compose](../../deploy/compose.lab.yaml) · [alcance de la recuperación](../verificacion-final.md#verificación-pública-y-colaboración).
