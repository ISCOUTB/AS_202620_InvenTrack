# Evidencia S13 — Inventario de activos, datos y controles

## 1. Propósito y alcance

Este inventario describe el estado real de seguridad del MVP de InvenTrack
antes de priorizar amenazas y asignar mitigaciones. Se distingue entre
capacidades implementadas, controles operativos y riesgos que permanecen
aceptados o fuera de alcance.

La aplicación es un monolito modular con arquitectura hexagonal por módulo.
El despliegue usa un contenedor Docker y repositorios en memoria; no hay una
base de datos ni un proveedor de identidad integrado en el MVP.

## 2. Activos y datos protegidos

| Activo / dato | Importancia | Módulo dueño | Operaciones relevantes | Estado actual |
|---|---|---|---|---|
| Catálogo de productos (`id`, `nombre`, `activo`) | Alto: identifica los bienes gestionados y habilita movimientos válidos. | `productos` | Crear, consultar y desactivar productos. | Implementado en repositorio en memoria. |
| Stock disponible (`producto_id`, `cantidad`) | Crítico: un valor incorrecto afecta decisiones y ventas. | `inventario` | Registrar entradas, salidas y consultar stock. | Implementado con exclusión mutua por SKU. |
| Movimientos de inventario | Crítico: soporta trazabilidad y auditoría. | `inventario` | Registrar entradas y salidas; consultar historial. | Implementado como historial en memoria e inmutable. |
| Eventos de auditoría | Alto: permiten rastrear la publicación y procesamiento de movimientos. | `inventario` / mensajería | Publicar, deduplicar, reintentar y enviar a DLQ. | Implementado en broker simulado en memoria. |
| Claves de idempotencia | Alto: evitan repetir comandos después de reintentos HTTP. | `inventario` | Reservar clave, comparar fingerprint y reproducir resultado. | Implementado en memoria durante la vida del proceso. |
| Métricas y logs técnicos | Medio-alto: soportan diagnóstico y evidencia de operación. | Aplicación / infraestructura | Registrar solicitudes, duración, estado y métricas p95. | Implementado; no contiene autenticación ni control de acceso. |
| Usuarios, roles y permisos | Alto por el impacto potencial en operaciones administrativas. | `usuarios` | Planeado para autenticación y autorización. | No implementado en el MVP actual. |

La propiedad detallada de estos datos y sus fronteras está documentada en
[propiedad-datos.md](propiedad-datos.md).

## 3. Superficies de entrada y salida

| Superficie | Exposición | Datos que recibe o entrega | Control actual |
|---|---|---|---|
| `POST /productos` | Pública si el despliegue no añade una capa externa. | Identificador y nombre del producto. | Validación Pydantic y reglas del caso de uso; sin autenticación. |
| `DELETE /productos/{producto_id}` | Pública si el despliegue no añade una capa externa. | Identificador del producto. | Protege productos con historial; sin autorización por rol. |
| `POST /inventario/{producto_id}/entradas` | Pública si el despliegue no añade una capa externa. | Cantidad, `X-Correlation-ID`, `X-Idempotency-Key`. | Validación positiva, idempotencia y manejo de errores; sin autenticación. |
| `POST /inventario/{producto_id}/salidas` | Pública si el despliegue no añade una capa externa. | Cantidad, `X-Correlation-ID`, `X-Idempotency-Key`. | Validación positiva, lock por SKU, idempotencia y control de stock; sin autenticación. |
| `GET /inventario/{producto_id}` | Pública si el despliegue no añade una capa externa. | Identificador del producto; devuelve stock. | Validación de existencia; sin autenticación. |
| `GET /health` y `/` | Pública por diseño operativo. | Estado técnico y enlaces de servicio. | Sin datos de negocio. |
| `GET /metrics` | Pública en la aplicación actual. | Contadores, rutas, estados y latencias. | Sin autenticación ni autorización. |
| `GET /docs` | Pública por configuración predeterminada de FastAPI. | Esquema y documentación del API. | No contiene credenciales; puede revelar la superficie del API. |
| Broker simulado y consumidor de auditoría | Interna al proceso. | Eventos con `event_id`, `correlation_id`, tipo y datos del movimiento. | Deduplicación, reintentos, backoff y DLQ en memoria. |

## 4. Dependencias y componentes de confianza

| Componente | Función | Confianza / riesgo relevante | Estado |
|---|---|---|---|
| FastAPI y Pydantic | API HTTP y validación de payloads. | La superficie HTTP depende de sus versiones fijadas. | Dependencias fijadas en `requirements.txt`. |
| Uvicorn | Servidor ASGI. | Expone la aplicación en el contenedor. | Ejecutado como usuario no root. |
| Python base `3.11-slim` | Runtime del contenedor. | Imagen externa que debe mantenerse actualizada. | Definida en `Dockerfile`. |
| Render y Dokploy | Plataformas de despliegue documentadas. | Disponibilidad, configuración y protección del tráfico dependen de la plataforma. | Configuradas fuera del código de la aplicación. |
| GitHub Actions / SonarCloud | CI y análisis de calidad. | Procesan código y resultados del repositorio. | Configurados en `.github/workflows/` y `sonar-project.properties`. |
| Repositorios `InMemory` | Persistencia temporal del MVP. | Pérdida de datos ante reinicio y falta de coordinación entre réplicas. | Decisión aceptada en ADR-0012. |

Las versiones directas están declaradas en
[requirements.in](../requirements.in), y el lock con hashes está en
[requirements.txt](../requirements.txt). El análisis de vulnerabilidades de
esas dependencias se documentará en el siguiente paso.

## 5. Controles de seguridad y consistencia existentes

| Control | Amenaza que reduce | Evidencia | Cobertura |
|---|---|---|---|
| Validación de payloads con Pydantic | Cantidades inválidas y entrada malformada. | `MovimientoRequest.cantidad` usa `Field(gt=0)`. | Solo validación de forma y reglas básicas. |
| Exclusión mutua por SKU | Condiciones de carrera y stock negativo. | `asyncio.Lock` en el caso de uso de inventario. | Una instancia del proceso. |
| Idempotencia HTTP | Duplicación por reintentos de una solicitud. | `InMemoryIdempotencyStore` y ADR-0017. | Una instancia y mientras el proceso siga activo. |
| Deduplicación de eventos | Procesamiento repetido de auditoría. | `processed_events` y `_in_flight_keys` del broker. | En memoria y por proceso. |
| Reintentos y DLQ | Fallos transitorios o persistentes del consumidor. | `SimuladorBrokerMensajeria`. | No durable ante reinicio. |
| Separación modular y propiedad única | Escrituras directas entre dominios. | ADR-0001, ADR-0003 y `docs/propiedad-datos.md`. | Regla arquitectónica, no enforcement automático completo. |
| Usuario no root en Docker | Impacto de una intrusión dentro del contenedor. | `USER appuser` en `Dockerfile`. | No sustituye el aislamiento del despliegue. |
| Logs JSON y métricas | Diagnóstico y trazabilidad técnica. | Middleware de observabilidad en `app/main.py`. | No es control de acceso ni auditoría de identidad. |
| Lockfile con hashes | Alteración o variación de paquetes instalados. | Instalación con `--require-hashes`. | No reemplaza un escaneo de vulnerabilidades. |

## 6. Controles ausentes o fuera del MVP

- Autenticación de usuarios.
- Autorización basada en roles y permisos.
- Gestión de sesiones, tokens o credenciales.
- Persistencia durable, copias de seguridad y restauración.
- Cifrado gestionado por la aplicación para datos almacenados.
- Registro de identidad del actor que ejecutó cada movimiento.
- Retención, acceso restringido y redacción de logs.
- Coordinación de idempotencia y locks entre réplicas.
- Escaneo de vulnerabilidades de dependencias como evidencia S13.

Estas ausencias deben aparecer como amenazas o limitaciones en la matriz
priorizada; no deben presentarse como controles implementados.

## 7. Fuentes revisadas

- [ADR-0001 — Monolito modular con hexagonal por módulo](adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md).
- [ADR-0002 — Control de concurrencia](adr/0002-control-concurrencia-memoria-inventario.md).
- [ADR-0012 — Repositorios en memoria](adr/0012-mantener-repositorios-en-memoria-en-el-mvp.md).
- [ADR-0016 — Eventos de auditoría](adr/0016-integrar-eventos-de-auditoria-en-movimientos.md).
- [ADR-0017 — Idempotencia HTTP](adr/0017-idempotencia-http-en-comandos-de-inventario.md).
- [Propiedad de datos](propiedad-datos.md).
- [Dockerfile](../Dockerfile).
- [requirements.in](../requirements.in) y [requirements.txt](../requirements.txt).

## 8. Resultado del análisis de dependencias

### Método reproducible

Se ejecutaron los siguientes comandos desde la raíz del repositorio:

```powershell
python -m pip check
python -m pip_audit -r requirements.txt
```

Resultado de `pip check`: **sin dependencias rotas**.

Resultado de `pip-audit` al 30 de octubre de 2026: **18 hallazgos
reportados en 3 paquetes**. El número de hallazgos incluye identificadores
repetidos por la resolución del lockfile; los paquetes afectados son:

| Paquete | Versión fijada | Identificadores reportados | Versión mínima de corrección reportada | Tipo |
|---|---:|---|---:|---|
| `certifi` | 2026.7.22 | `PYSEC-2026-4320` | 2026.10.18 | Transitiva de `httpx` / cliente HTTP. |
| `starlette` | 0.38.6 | `PYSEC-2026-1943`, `PYSEC-2026-1941`, `PYSEC-2026-161`, `PYSEC-2026-2281`, `PYSEC-2026-2280`, `PYSEC-2026-249`, `PYSEC-2026-248` | Entre 0.40.0 y 1.3.1 según el identificador | Transitiva de `fastapi`. |
| `pytest` | 8.3.3 | `PYSEC-2026-1845` | 9.0.3 | Directa de desarrollo y pruebas. |

El escaneo no se interpreta como una vulnerabilidad explotable confirmada en
la aplicación: identifica versiones con avisos publicados y exige revisar
compatibilidad y alcance antes de actualizar. En particular, `starlette`
está fijada por la versión actual de `fastapi`; actualizarla de forma aislada
podría romper las restricciones de compatibilidad del framework.

### Conclusión para la matriz de amenazas

El análisis de dependencias produce una amenaza de prioridad **alta para la
cadena de suministro**: una vulnerabilidad conocida en una dependencia del
runtime puede afectar la superficie HTTP o el cliente usado por las pruebas.
La mitigación debe incluir:

1. Actualizar conjuntamente `fastapi`, `starlette` y dependencias relacionadas
   a versiones compatibles.
2. Actualizar `certifi` y regenerar el lockfile con hashes.
3. Actualizar `pytest` por separado como dependencia de desarrollo.
4. Ejecutar nuevamente `pip-audit`, `pip check` y la suite de pruebas.
5. Incorporar el escaneo reproducible al CI para evitar regresiones.

La actualización de versiones y la configuración del CI no se consideran
realizadas en este paso; quedan como acciones de mitigación para la matriz
priorizada.
