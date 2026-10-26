# Análisis de Fallos Parciales e Integración Distribuida — Semana 11

- **Sistema:** InvenTrack — Monolito Modular
- **Integración Analizada:** Módulo de `Inventario` ↔ Módulo de `Productos` (vía `ValidadorDeProductoAdapter`)
- **Contrato y Patrones Relacionados:** [ADR-0003](../adr/0003-puertos-y-adaptadores-para-comunicacion-inter-modulo.md) (Integración mediante Puertos de Aplicación), [ADR-0002](../adr/0002-control-concurrencia-inventario.md) (Control de Concurrencia por SKU), [ADR-0010](../adr/0010-decision-extraccion-microservicios.md) (Evaluación No-Extracción) y [ADR-0011](../adr/0011-idempotencia-y-sagas-en-movimientos.md) (Idempotencia y Sagas).
- **Corte:** Tercer Corte (Sistemas Distribuidos y Tolerancia a Fallos)

---

## 1. Contexto de la Integración Principal

En la arquitectura actual de InvenTrack, el módulo de **`inventario`** requiere validar la existencia y el estado activo de un producto en el módulo de **`productos`** antes de registrar cualquier entrada o salida de stock. 

Aunque actualmente ambos módulos coexisten dentro del mismo proceso ejecutable (Monolito Modular en FastAPI), esta frontera representa el **límite de contexto delimitado (*Bounded Context*) principal del sistema**. Si esta integración se desplegara sobre una red (extracción a microservicios hipotética), estaría sujeta a las *8 Falacias de la Computación Distribuida* (la red no es confiable, la latencia no es cero, el ancho de banda no es infinito, etc.).

A continuación se analizan los tres escenarios fundamentales de fallo parcial de esta integración y su estrategia de mitigación.

---

## 2. Matriz de Modos de Fallo Parcial y Mitigaciones

| Modo de Fallo Parcial | Escenario Concreto en `Inventario ↔ Productos` | Impacto en el Dominio | Táctica / Mitigación Arquitectónica | Estado en el Código / Plan de Implementación |
| :--- | :--- | :--- | :--- | :--- |
| **1. No Responde (Timeout / Caída)** | El adaptador del módulo `productos` no emite respuesta (falla de red o caída del proceso remoto) durante la llamada de verificación de SKU desde `inventario`. | El hilo o corrutina queda bloqueado indefinidamente esperando respuesta, reteniendo el cerrojo asíncrono (`asyncio.Lock`) sobre el SKU y provocando denegación de servicio (*cascading failure*). | **Timeout Estricto + Circuit Breaker:** <br>1. Definir un tiempo máximo de espera ($t \le 2.0\text{ s}$) mediante clientes HTTP asíncronos (`httpx`).<br>2. Implementar un patrón *Circuit Breaker* (Estado: *Closed*, *Open*, *Half-Open*) que abra el circuito tras 5 fallos consecutivos, respondiendo inmediatamente HTTP `503 Service Unavailable` sin saturar la red. | **Mitigado por arquitectura monolítica en memoria:** Al ejecutarse en el mismo proceso, la consulta es en memoria.<br>*Plan distribuido:* Configuración de timeouts y breakers en adaptadores HTTP de infraestructura. |
| **2. Responde Tarde (Alta Latencia / Congestión)** | La consulta de verificación de producto experimenta latencias anómalas ($> 1.5\text{ s}$) debido a saturación en el servidor o contención de recursos. | Degradación severa del tiempo de respuesta en el registro de salidas, haciendo que las peticiones concurrentes acumulen cola en el *event loop* y superen el umbral de $p95 \le 400\text{ ms}$. | **Exclusión Mutua con Límite de Espera + Liberación Limpia:** <br>Uso de corrutinas con tiempo de espera acotado sobre la adquisición del lock de SKU. Si la respuesta excede el tiempo tolerable, se aborta la transacción y se libera el cerrojo sin corromper el stock. | **Implementado en el código:** Manejo asíncrono en FastAPI (`app/main.py`) y control de concurrencia local con timeout de 2 s mediante `asyncio.Lock()` por SKU (`app/inventario/application/registrar_movimiento.py`). |
| **3. Responde Dos Veces (Duplicidad por Reintentos)** | Un cliente o cliente HTTP de red reintenta un registro de movimiento (`POST /inventario/{sku}/salidas`) tras un timeout o fallo temporal de conexión, enviando dos veces la misma instrucción de descuento. | Riesgo de **doble descuento de stock** sobre el mismo producto, generando quiebres de inventario o saldos negativos inconsistentes. | **Deduplicación Durable + Clave de Idempotencia (*Idempotency Key*):** <br>1. Exigir cabecera HTTP `X-Idempotency-Key` en operaciones mutativas.<br>2. Almacenar la clave, el payload y el resultado en un almacén persistente de claves procesadas.<br>3. Si se recibe una petición repetida con la misma clave, retornar el resultado almacenado en lugar de reejecutar la lógica de negocio. | **PENDIENTE RAZONADO (No Deduplica actualmente):** La serialización por `asyncio.Lock` en `registrar_movimiento.py:37-78` garantiza orden y atomicidad, **pero reaplica cada comando repetido sin deduplicar**. La deduplicación durable es un pendiente explícito documentado en el [ADR-0011](../adr/0011-idempotencia-y-sagas-en-movimientos.md). |

---

## 3. Anexo de Riesgos y Deuda Técnica (arc42 §11)

La **Sección 11 del documento arc42 (`docs/arc42/arc42-template-EN.md`)** formaliza el análisis de fallos distribuidos:

### 11.3 Fallos Parciales en Integraciones Distribuidas
- **Mitigación de Latencia y Bloqueo:** El sistema previene bloqueos en cascada mediante llamadas asíncronas y timeouts acotados en los adaptadores cruzados entre módulos ([ADR-0003](../adr/0003-puertos-y-adaptadores-para-comunicacion-inter-modulo.md)).
- **Límite de Idempotencia (Pendiente Documentado):** La serialización de transacciones sobre el mismo SKU ([ADR-0002](../adr/0002-control-concurrencia-inventario.md)) garantiza atomicidad y evita condiciones de carrera en memoria, pero **no evita que un comando idéntico reintentado por el cliente se aplique dos veces**. El diseño formal de la clave de idempotencia durable (`X-Idempotency-Key`) y las condiciones para adoptar patrones Sagas/Outbox se encuentran formalizados como un pendiente razonado en el [ADR-0011](../adr/0011-idempotencia-y-sagas-en-movimientos.md).