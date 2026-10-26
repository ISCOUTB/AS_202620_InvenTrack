# ADR-0013: Evaluación de Mensajería Asíncrona frente a Invocación Síncrona para Procesos de Inventario

- **Estado:** Aceptado
- **Contexto:** Tercer Corte (Sistemas Distribuidos y Tolerancia a Fallos)
- **Sistema:** InvenTrack — Monolito Modular
- **Componentes Afectados:** Módulo de `Inventario`, Módulo de Notificaciones / Auditoría de Movimientos.

---

## 1. Contexto y Problema

En la arquitectura actual de InvenTrack, las operaciones mutativas de inventario (`POST /inventario/{sku}/entradas` y `POST /inventario/{sku}/salidas`) se ejecutan de manera estrictamente síncrona dentro del ciclo de vida de la petición HTTP, utilizando un cerrojo en memoria por SKU (`asyncio.Lock`) para garantizar consistencia local. 

Sin embargo, ante requerimientos futuros de desacoplamiento temporal, procesamiento en segundo plano (auditorías pesadas, notificaciones masivas a proveedores y sincronización con sistemas externos), la invocación puramente síncrona genera acoplamiento temporal fuerte, vulnerabilidad ante picos de tráfico y riesgo de pérdida de tareas secundarias si falla el hilo de ejecución principal.

---

## 2. Decisión Arquitectónica

Se decide **adoptar un modelo de procesamiento híbrido basado en eventos asíncronos con garantía de entrega *At-Least-Once*** para tareas desacopladas (como auditorías y notificaciones), manteniendo la consistencia transaccional fuerte local mediante exclusión mutua en las operaciones críticas de stock. 

Para validar este comportamiento, se ha implementado y probado un simulador de broker de mensajes con políticas de reintento, backoff exponencial, Dead Letter Queue (DLQ) y deduplicación por clave de idempotencia (`app/messaging/broker_simulador.py`).

---

## 3. Opciones Evaluadas

### Opción A: Invocación Síncrona Directa (Estado Actual del MVP)
* **Descripción:** Cada operación realiza todas sus subtareas (actualizar stock, registrar auditoría, notificar) en el mismo hilo HTTP antes de responder al cliente.
* **Ventajas:** Simplicidad conceptual extrema, transaccionalidad inmediata en memoria, fácil depuración local.
* **Desventajas:** Alta latencia acumulativa para el usuario final, acoplamiento rígido entre componentes, incapacidad de reintentar subtareas secundarias en segundo plano ante fallos temporales.

### Opción B: Mensajería Asíncrona con Broker (Opción Seleccionada para Procesos Desacoplados)
* **Descripción:** Producción de eventos de dominio (`MovimientoDeInventarioRegistrado` v1.0.0) hacia un canal gestionado con reintentos automáticos, backoff y derivación a DLQ ante fallos persistentes.
* **Ventajas:** Desacoplamiento temporal de componentes, resiliencia ante caídas transitorias de servicios externos, escalabilidad horizontal independiente de los consumidores.
* **Desventajas:** Complejidad operacional en la infraestructura de mensajería, necesidad de manejar consistencia eventual y duplicados (idempotencia).

---

## 4. Consecuencias y Compensaciones (*Trade-offs*)

1. **Garantía de Entrega (*At-Least-Once*):** Se asegura que ningún evento de movimiento se pierda; sin embargo, obliga a los consumidores a implementar idempotencia mediante el uso de la cabecera/clave de idempotencia.
2. **Trazabilidad Extrema:** El uso de `correlation_id` en el contrato de mensajes permite seguir el ciclo de vida del mensaje desde el productor HTTP hasta el consumidor y su eventual registro en la DLQ.
3. **Manejo de Fallos No Bloqueantes:** Los errores en tareas secundarias (ej. auditoría o notificaciones) ya no comprometen la respuesta HTTP principal de registro de inventario, derivando los fallos irrecuperables a una Cola de Mensajes Fallidos (*Dead Letter Queue*).