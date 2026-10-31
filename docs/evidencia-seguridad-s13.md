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

## 9. Tabla de amenazas priorizadas

La prioridad combina impacto sobre los activos críticos y probabilidad de
ocurrencia en el despliegue actual. La escala usada es **Crítica**, **Alta**,
**Media** y **Baja**. Una mitigación marcada como pendiente no se presenta
como una capacidad disponible del sistema.

| ID | Amenaza | Activo afectado | Impacto | Probabilidad | Prioridad | Mitigación asignada | Estado / evidencia |
|---|---|---|---|---|---|---|---|
| T-01 | Un tercero ejecuta entradas, salidas, creación o eliminación de productos porque el API no exige autenticación ni autorización. | Stock, productos y movimientos. | Crítico | Alta | **Crítica** | Incorporar autenticación y autorización por roles; restringir operaciones administrativas y registrar el actor. | Pendiente; el módulo `usuarios` aún no implementa estos controles. |
| T-02 | Una dependencia con vulnerabilidad conocida permite afectar la superficie HTTP o el entorno de ejecución. | API, runtime y cadena de suministro. | Alto | Alta | **Alta** | Actualizar versiones compatibles de `fastapi`/`starlette`, `certifi` y `pytest`; regenerar hashes y ejecutar `pip-audit` en CI. | Pendiente; `pip-audit` reportó 18 hallazgos en 3 paquetes. |
| T-03 | Un reinicio o redeploy elimina el stock, movimientos, claves de idempotencia y eventos almacenados en memoria. | Stock, historial, auditoría e idempotencia. | Crítico | Media-alta | **Alta** | Migrar a persistencia durable con backups y restauración; usar un almacén compartido antes de habilitar varias réplicas. | Riesgo aceptado del MVP; ADR-0012 y ADR-0017. |
| T-04 | Dos réplicas procesan el mismo comando o actualizan el mismo SKU sin compartir locks ni claves de idempotencia. | Stock y movimientos. | Crítico | Media | **Alta** | Mantener una sola instancia en el MVP o introducir transacciones y coordinación distribuida en una persistencia compartida. | Mitigado solo dentro de una instancia; límites documentados en ADR-0002 y ADR-0017. |
| T-05 | Un consumidor procesa un evento duplicado o falla después de modificar el stock y antes de completar la auditoría. | Movimientos y eventos de auditoría. | Alto | Media | **Media-alta** | Mantener consumidores idempotentes, reintentos y DLQ; evolucionar a Outbox durable para cerrar la ventana entre stock y publicación. | Mitigación parcial; broker y DLQ son volátiles. |
| T-06 | La exposición pública de `/metrics` o `/docs` revela rutas, estados, latencias o detalles operativos útiles para reconocimiento. | Información operacional y superficie del API. | Medio | Alta | **Media-alta** | Restringir `/metrics` y documentación en producción mediante autenticación, red privada o configuración de despliegue; mantener `/health` mínimo y público. | Pendiente; actualmente las rutas están expuestas por la aplicación. |
| T-07 | Los logs y eventos no identifican al usuario que ejecutó un movimiento y podrían conservar más información de la necesaria. | Trazabilidad y datos operativos. | Alto | Media | **Media-alta** | Añadir identidad del actor, política de retención y redacción; restringir acceso al sistema de logs. | Pendiente; actualmente se registran `event_id`, `correlation_id` y datos técnicos, no identidad autenticada. |
| T-08 | Un payload malformado o una cantidad inválida provoca errores o altera reglas del dominio. | Stock y disponibilidad del servicio. | Alto | Media | **Media** | Mantener validación Pydantic, límites de entrada y pruebas contractuales; devolver errores HTTP explícitos. | Parcialmente implementado; `cantidad` exige ser mayor que cero y el contrato se valida en CI. |
| T-09 | Un atacante o proceso comprometido accede con privilegios excesivos dentro del contenedor. | Código, memoria y datos del proceso. | Alto | Baja-media | **Media** | Mantener usuario no root, imagen mínima y permisos mínimos; escanear imagen y fijar actualizaciones de la imagen base. | Mitigación parcial; `Dockerfile` usa `python:3.11-slim` y `USER appuser`. |
| T-10 | La manipulación o sustitución de paquetes altera el software instalado durante el build. | Cadena de suministro. | Alto | Baja-media | **Media** | Mantener `requirements.txt` con hashes, instalación `--require-hashes`, revisión de cambios y escaneo automático. | Hashes implementados; escaneo continuo pendiente. |

### Orden de atención recomendado

1. **T-01 — Acceso sin autenticación ni autorización.** Es la amenaza más
   grave porque permite modificar directamente activos críticos desde el API.
2. **T-02 — Dependencias vulnerables.** Tiene hallazgos concretos y afecta
   componentes del runtime; debe resolverse antes de presentar el despliegue
   como endurecido.
3. **T-03 y T-04 — Pérdida o divergencia del estado.** Son riesgos
   estructurales del almacenamiento en memoria y del escalamiento horizontal.
4. **T-05, T-06 y T-07 — Auditoría, exposición operacional y privacidad.**
   Requieren controles coordinados con la sección de privacidad.
5. **T-08, T-09 y T-10 — Defensa en profundidad.** Ya tienen controles
   parciales, pero necesitan validación y automatización continua.

Las mitigaciones T-01, T-03, T-04, T-05, T-06 y T-07 pueden cambiar la
estructura o los límites de confianza del sistema. Si se aceptan para
implementación, se deberá crear o actualizar un ADR antes de presentarlas como
decisiones arquitectónicas.

## 10. Privacidad y tratamiento de datos personales

### 10.1 Tratamiento efectivo en el MVP actual

El MVP revisado no implementa el módulo `usuarios`, autenticación, cuentas,
correo electrónico, teléfonos, documentos de identidad ni perfiles de
personas. Por tanto, los endpoints actuales no solicitan directamente datos
personales para crear productos o registrar movimientos.

Los siguientes datos técnicos pueden llegar desde el cliente o generarse
durante la operación:

| Dato | ¿Personal en el contexto? | Finalidad | Estado |
|---|---|---|---|
| `X-Correlation-ID` | Puede serlo si el cliente incluye un identificador asociado a una persona. | Trazar una solicitud entre componentes. | Recibido opcionalmente y escrito en eventos/logs. |
| `X-Idempotency-Key` | Normalmente es un identificador técnico, pero no debe contener nombres, correos o documentos. | Evitar repetir un comando HTTP. | Recibido opcionalmente y almacenado temporalmente en memoria. |
| `event_id` | Identificador técnico; no identifica por sí solo a una persona. | Identificar un evento de auditoría. | Generado por el servidor y registrado. |
| IP, user-agent y datos de acceso del proveedor | Pueden ser datos personales o identificables. | Seguridad y operación de la plataforma. | Posible tratamiento en Render, Dokploy, proxy o sistema de logs; no es almacenado explícitamente por la aplicación. |

La aplicación registra datos técnicos de solicitudes y eventos, pero no tiene
un campo de identidad autenticada del actor. Por ello, actualmente no puede
cumplir una trazabilidad personal de quién realizó cada movimiento, aunque el
historial del movimiento sí se conserve.

### 10.2 Datos previstos si se implementa `usuarios`

La siguiente tabla describe el tratamiento que deberá definirse antes de
activar autenticación y roles. No representa funcionalidades existentes:

| Dato previsto | Finalidad estrictamente necesaria | Base propuesta | Salvaguardas requeridas |
|---|---|---|---|
| Nombre o identificador laboral | Identificar al usuario dentro de la PYME. | Autorización previa, expresa e informada del titular, o la excepción legal aplicable según el responsable del tratamiento. | Minimización, acceso restringido y actualización. |
| Correo electrónico | Autenticación, recuperación de cuenta y notificaciones operativas, si se justifican. | Autorización informada para la finalidad definida; revisar si existe una obligación contractual o legal aplicable. | No usarlo para fines distintos sin nueva información/autorización. |
| Rol y estado de acceso | Aplicar autorización y retirar acceso. | Necesidad de administrar la relación laboral/operativa y autorización o base legal aplicable. | Principio de mínimo privilegio y revisión de permisos. |
| Identidad del actor en un movimiento | Trazabilidad y auditoría de operaciones de inventario. | Necesidad de seguridad y auditoría del servicio, informada al titular y documentada por el responsable. | Inmutabilidad, acceso restringido y retención definida. |
| Credenciales o secretos de autenticación | Verificar identidad. | Necesidad de prestar el servicio de autenticación. | Almacenar solo hashes de contraseñas; nunca registrar contraseñas ni tokens en logs. |

La base jurídica final debe ser aprobada por el responsable del tratamiento
de la PYME y reflejada en el aviso o política de privacidad. Para el contexto
colombiano, la referencia normativa inicial es la **Ley 1581 de 2012** y su
reglamentación aplicable; esta documentación no sustituye una revisión legal.
No se deben recolectar datos sensibles ni documentos de identidad para el MVP
si no existe una finalidad y base legal específica.

### 10.3 Principios y obligaciones operativas

Antes de activar el módulo de usuarios se debe definir:

- Finalidad concreta y aviso de privacidad visible para los usuarios.
- Autorización o base legal aplicable y evidencia de su gestión.
- Inventario de campos, responsable del tratamiento y encargados externos.
- Retención y eliminación de cuentas, logs, eventos y respaldos.
- Canal para consultar, actualizar, corregir o solicitar la supresión de datos,
  según los derechos aplicables.
- Restricción de acceso a logs y métricas; no incluir credenciales, tokens ni
  datos personales innecesarios.
- Cifrado en tránsito y protección de secretos en el proveedor de despliegue.
- Procedimiento para incidentes y comunicación al responsable del tratamiento.

### 10.4 Conclusión de privacidad para S13

El riesgo de privacidad actual se concentra en la ausencia de autenticación,
la posible inclusión de datos personales en identificadores enviados por
clientes y los logs gestionados por la plataforma. La mitigación inmediata es
prohibir datos personales en `X-Correlation-ID` y `X-Idempotency-Key`, revisar
la retención y el acceso a logs, y documentar la política antes de habilitar
usuarios reales. La implementación de identidad, roles y auditoría por actor
requiere una decisión arquitectónica posterior.
