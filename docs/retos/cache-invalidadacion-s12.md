# Diseño de Caché y Política de Invalidación — Semana 12

- **Sistema:** InvenTrack — Monolito Modular
- **Contexto:** Tercer Corte (Optimización de Lecturas, Rendimiento y Consistencia)
- **Componentes Afectados:** Módulo de `Inventario` y Módulo de `Productos`.

---

## 1. Estrategia y Arquitectura de Caché

Para optimizar las consultas frecuentes de stock actual y evitar la saturación de los repositorios en memoria/base de datos durante picos de lectura (`GET /inventario/{sku}` y `GET /productos/{sku}`), se implementa un patrón **Cache-Aside (Lectura perezosa con llenado bajo demanda)** combinado con una estrategia de **Doble Capa de Invalidación**.

### Características Técnicas del Almacén de Caché
* **Tecnología:** Almacén en memoria de alta velocidad basado en diccionarios seguros para hilos / estructuras LRU (*Least Recently Used*) optimizadas en Python.
* **Ámbito de Almacjamiento:** Datos de solo lectura o lectura intensiva (metadatos de productos, saldos actuales de inventario con bajo factor de mutación concurrente).

---

## 2. Política de Expiración e Invalidación

Para mitigar el riesgo de servir datos desactualizados (*stale data*), el sistema implementa una política híbrida de invalidación:

| Mecanismo de Invalidación | Funcionamiento Técnico | Escenario de Uso Ideal |
| :--- | :--- | :--- |
| **1. Invalidación por Expiración de Tiempo (TTL - Time To Live)** | Cada clave almacenada en caché posee un tiempo de vida máximo configurable ($TTL = 60\text{ segundos}$). Tras este lapso, la clave expira automáticamente. | Consultas de catálogos de productos y listados generales donde un desfase temporal menor a un minuto es aceptable. |
| **2. Invalidación Activa por Evento de Dominio (Event-Driven Invalidation)** | Cuando se ejecuta una mutación crítica (ej. un registro de entrada o salida de stock mediante el evento `MovimientoDeInventarioRegistrado`), el sistema emite una señal de invalidación que borra o actualiza inmediatamente la clave en la caché del SKU afectado. | Saldos de inventario críticos (`GET /inventario/{sku}`), garantizando que inmediatamente después de un movimiento, la siguiente lectura refleje el stock correcto. |

---

## 3. Diagrama de Flujo del Patrón Cache-Aside con Invalidación

1. **Solicitud de Lectura:** El cliente solicita el stock del producto `SKU-001` (`GET /inventario/SKU-001`).
2. **Consulta a Caché:** El adaptador de inventario revisa si existe la clave `cache:inventario:SKU-001`.
   * *Si hay caché (Hit):* Retorna el valor inmediatamente (Latencia $< 5\text{ ms}$).
   * *Si no hay caché (Miss):* Consulta el repositorio persistente, almacena el resultado en caché con su respectivo TTL y lo retorna al cliente.
3. **Solicitud de Escritura / Mutación:** El cliente registra un movimiento (`POST /inventario/SKU-001/salidas`).
4. **Invalidación Inmediata:** Se actualiza el stock de forma atómica (`asyncio.Lock`) y se ejecuta la invalidación explícita (`cache.invalidate("cache:inventario:SKU-001")`), previniendo lecturas inconsistentes posteriores.