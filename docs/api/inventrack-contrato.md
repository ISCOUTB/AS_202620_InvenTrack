# Contrato de API de InvenTrack

> **Qué es este documento:** El contrato funcional y arquitectónico de la API de InvenTrack. Describe la comunicación HTTP/JSON del sistema, las operaciones expuestas, las reglas de desacoplamiento entre módulos y el manejo de concurrencia en el inventario.
>
> **Qué NO es:** Un listado de funcionalidades ideales. Refleja estrictamente el MVP implementado y verificado en la entrega actual.

---

## 1. Alcance de la API

InvenTrack es un sistema inteligente de gestión de inventarios para PYMEs localizadas que permite registrar productos, auditar sus entradas/salidas con control estricto de concurrencia y mantener la trazabilidad de los movimientos sin inconsistencias de stock.

| Actor o sistema | Necesita realizar | Operación o interacción |
|---|---|---|
| Usuario / Cliente HTTP | Crear un nuevo producto en el catálogo | `POST /productos` |
| Usuario / Cliente HTTP | Eliminar o desactivar un producto | `DELETE /productos/{producto_id}` |
| Usuario / Cliente HTTP | Registrar entrada de mercancía | `POST /inventario/{producto_id}/entradas` |
| Usuario / Cliente HTTP | Registrar salida/venta de mercancía | `POST /inventario/{producto_id}/salidas` |
| Usuario / Cliente HTTP | Consultar existencias de un producto | `GET /inventario/{producto_id}` |
| Módulo `productos` | Verificar si un producto tiene historial | Invocación interna al puerto `ConsultarHistorialMovimientos` |
| Módulo `inventario` | Validar existencia y estado activo de un producto | Invocación interna al puerto `ValidadorDeProducto` |

---

## 2. Convenciones del contrato

- **Estilo de integración:** REST síncrono sobre HTTP.
- **Formato de intercambio:** JSON.
- **Servidor local:** `http://localhost:8000`.
- **Autenticación:** No implementada en el MVP actual.
- **Versionado:** `1.0.0` (Contrato OpenAPI versionado).
- **Mecanismo de Concurrencia:** Cerrojo en memoria (`asyncio.Lock` por SKU) con tiempo límite de espera ($2\text{ s}$) para prevenir *race conditions* en ráfagas concurrentes (Reto Corte 1).
- **Estrategia de Borrado:** Borrado físico si el producto no tiene movimientos; borrado lógico (desactivación) si cuenta con historial en inventario (Escenario ESC-02).

---

## 3. Contrato síncrono REST (OpenAPI)

El contrato técnico ejecutable se encuentra definido y versionado en:

`contracts/openapi/v1.json`

### Endpoints Principales

| Método | Endpoint | Código Éxito | Códigos de Error | Propósito |
|---|---|---|---|---|
| `POST` | `/productos` | `201 Created` | `422` | Registrar un producto en el sistema. |
| `DELETE` | `/productos/{producto_id}` | `200 OK` | `404` | Eliminar físicamente o desactivar lógicamente un producto. |
| `POST` | `/inventario/{producto_id}/entradas` | `200 OK` | `404`, `503` | Registrar incremento de stock sobre un SKU. |
| `POST` | `/inventario/{producto_id}/salidas` | `200 OK` | `404`, `409`, `503` | Registrar decremento de stock validando disponibilidad. |
| `GET` | `/inventario/{producto_id}` | `200 OK` | `404` | Consultar la cantidad actual en stock. |

---

## 4. Mapeo de Respuestas y Errores de Dominio

| Excepción de Dominio | Código HTTP | Razón / Significado |
|---|---|---|
| `ProductoNoEncontrado` / `ProductoInvalidoError` | `404 Not Found` | El producto no existe en la base de datos o está desactivado. |
| `ProductoSinStockError` | `404 Not Found` | El producto no posee un registro de existencias inicializado. |
| `StockInsuficienteError` | `409 Conflict` | La cantidad solicitada supera el stock disponible (evita stock negativo). |
| `TiempoDeEsperaLockAgotado` | `503 Service Unavailable` | El tiempo de espera del Mutex ($2\text{ s}$) expiró ante una alta contención concurrente. |

---

## 5. Contratos asíncronos

La API actual de InvenTrack no utiliza contratos asíncronos (AsyncAPI, colas de mensajería como RabbitMQ/Kafka o eventos de dominio asíncronos). Todas las operaciones de entrada/salida y consulta operan bajo la modalidad síncrona solicitud-respuesta para garantizar la consistencia inmediata del inventario.

---

## 6. Estado actual de implementación

| Operación o funcionalidad | En el contrato | Implementado actualmente |
|---|---|---|
| Creación de productos | Sí | Sí, mediante `POST /productos` |
| Borrado físico / lógico de productos | Sí | Sí, mediante `DELETE /productos/{producto_id}` |
| Entradas de inventario | Sí | Sí, mediante `POST /inventario/{producto_id}/entradas` |
| Salidas de inventario con validación de stock | Sí | Sí, mediante `POST /inventario/{producto_id}/salidas` |
| Consulta de stock por producto | Sí | Sí, mediante `GET /inventario/{producto_id}` |
| Aislamiento de concurrencia por SKU | Sí | Sí, mediante `asyncio.Lock` en memoria |
| Trazabilidad e historial de movimientos | Sí | Sí, en repositorio en memoria |
| Predicción de demanda con IA | No | No (declarado fuera de alcance en el MVP) |
| Autenticación y roles de usuario | No | No (planificado para entregas futuras) |

---

## 7. Relación con la Arquitectura Hexagonal

El sistema está estructurado mediante un Monolito Modular con Arquitectura Hexagonal por módulo (`productos` e `inventario`). Los módulos no se acoplan directamente a nivel de infraestructura ni base de datos, sino a través de **Puertos de Aplicación y Adaptadores Cruzados (ADR-0003)**.

```text
Cliente HTTP / Frontend
        │
        │ REST (HTTP + JSON)
        ▼
   FastAPI Routers
        │
  ┌─────┴───────────────────────────────┐
  │                                     │
  ▼                                     ▼
Módulo Productos              Módulo Inventario
  │                                     │
  ├─ CrearProducto                      ├─ RegistrarMovimiento
  ├─ EliminarProducto                   ├─ ConsultarHistorial
  │                                     │
  └───► [ Adaptador Cruzado ] ──────────┘
        VerificadorDeMovimientos
```
## 8. Versionado e Historial

La versión actual del contrato ejecutable es **`1.0.0`** y se ubica en `contracts/openapi/v1.json`.

| Versión | Fecha | Descripción |
|---|---|---|
| 1.0.0 | 2026-09-20 | Versión inicial del contrato OpenAPI HTTP para InvenTrack. Incluye catálogo de productos, registro de entradas/salidas de inventario con aislamiento por Mutex, y políticas de eliminación. |