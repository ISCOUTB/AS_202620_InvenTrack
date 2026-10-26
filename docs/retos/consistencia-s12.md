# Matriz de Mapeo de Operaciones y Modelos de Consistencia — Semana 12

- **Sistema:** InvenTrack — Monolito Modular
- **Contexto:** Tercer Corte (Sistemas Distribuidos, Consistencia y Tolerancia a Fallos)
- **Objetivo:** Definir explícitamente el modelo de consistencia aplicado a cada operación del dominio para prevenir quiebres de inventario y condiciones de carrera.

---

## 1. Matriz de Operaciones, Fronteras y Modelos de Consistencia

| Operación del Sistema / Endpoint | Módulo Involucrado | Modelo de Consistencia Elegido | Mecanismo de Garantía en el Código | Justificación de Negocio y Compensación (*Trade-off*) |
| :--- | :--- | :--- | :--- | :--- |
| **1. Registro de Entrada/Salida de Stock** <br>(`POST /inventario/{sku}/entradas` o `salidas`) | `Inventario` | **Consistencia Fuerte (Strong Consistency)** | **Exclusión Mutua Asíncrona:** Uso de `asyncio.Lock` dedicado por cada SKU (`app/inventario/application/registrar_movimiento.py`). | **Crítico:** Evita saldos negativos y condiciones de carrera concurrentes. *Trade-off:* Introduce una ligera cola de espera bajo alta concurrencia por SKU. |
| **2. Verificación de Existencia de Producto** <br>(Consulta interna cruzada) | `Inventario` ↔ `Productos` | **Consistencia Fuerte (Lectura Directa en Memoria)** | **Adaptador de Puerto de Aplicación:** Invocación directa síncrona en memoria mediante `ValidadorDeProductoAdapter`. | **Necesario:** Garantiza que no se opere sobre un SKU inexistente o inactivo. Al estar en un monolito modular, la latencia es cero. |
| **3. Auditoría y Registro de Eventos** <br>(Emisión de eventos de dominio) | `Inventario` ➔ Sistema de Mensajería | **Consistencia Eventual (Eventual Consistency)** | **Broker Asíncrono con Reintentos y DLQ:** Publicación del evento `MovimientoDeInventarioRegistrado` v1.0.0 (`app/messaging/broker_simulador.py`). | **Resiliencia:** Permite que fallos en servicios de auditoría o logging secundario no bloqueen ni fallen la operación principal de inventario. |
| **4. Consulta de Stock Disponible** <br>(`GET /inventario/{sku}`) | `Inventario` | **Consistencia de Lectura Consistente con Caché (Read-After-Write con TTL)** | **Caché en Memoria Local con Invalidación por Evento de Movimiento.** | **Rendimiento:** Optimiza el rendimiento en endpoints de alta lectura, tolerando un desfase menor a milisegundos compensado por eventos de invalidación. |

---

## 2. Análisis de Concurrencia y Control de Anomalías

### Anomalías Prevenidas
1. **Lost Updates (Actualizaciones Perdidas):** Prevenidas mediante el uso estricto del cerrojo en memoria (`asyncio.Lock`) por SKU, asegurando que dos peticiones simultáneas sobre el mismo producto no lean y escriban el stock superponiéndose.
2. **Double Spending / Double Discounting (Doble Descuento):** Mitigado mediante la validación de stock final mínimo ($\ge 0$) combinada con la estructura de claves de idempotencia en los adaptadores de entrada.