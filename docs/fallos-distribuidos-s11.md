# Análisis de Fallos Parciales e Integración Distribuida — Semana 11

- **Sistema:** InvenTrack — Monolito Modular
- **Integración Analizada:** Módulo de `Inventario` ↔ Módulo de `Productos` (vía `ValidadorDeProductoAdapter`)
- **Contrato y Patrón Relacionado:** ADR-0003 (Integración mediante Puertos de Aplicación) y ADR-0002 (Control de Concurrencia por SKU)
- **Corte:** Tercer Corte (Sistemas Distribuidos y Tolerancia a Fallos)

---

## 1. Contexto de la Integración Principal

En la arquitectura actual de InvenTrack, el módulo de **`inventario`** requiere validar la existencia y el estado activo de un producto en el módulo de **`productos`** antes de registrar cualquier entrada o salida de stock. 

Aunque actualmente ambos módulos coexisten dentro del mismo proceso ejecutable (Monolito Modular en FastAPI), esta frontera representa el **límite de contexto delimitado (*Bounded Context*) principal del sistema**. Si esta integración se desplegara sobre una red (extracción a microservicios), estaría sujeta a las *8 Falacias de la Computación Distribuida* (la red no es confiable, la latencia no es cero, el ancho de banda no es infinito, etc.).

A continuación se analizan los tres escenarios fundamentales de fallo parcial de esta integración y su estrategia de mitigación.

---

## 2. Matriz de Modos de Fallo Parcial y Mitigaciones

| Modo de Fallo Parcial | Escenario Concreto en `Inventario ↔ Productos` | Impacto en el Dominio | Táctica / Mitigación Arquitectónica | Estado en el Código / Plan de Implementación |
| :--- | :--- | :--- | :--- | :--- |
| **1. No Responde (Timeout / Caída)** | El adaptador del módulo `productos` no emite respuesta (falla de red o caída del proceso remoto) durante la llamada de verificación de SKU desde `inventario`. | El hilo o corrutina queda bloqueado indefinidamente esperando respuesta, reteniendo el cerrojo asíncrono (`asyncio.Lock`) sobre el SKU y provocando denegación de servicio (*cascading failure*). | **Timeout Estricto + Circuit Breaker:** <br>1. Definir un tiempo máximo de espera ($t \le 2.0\text{ s}$) mediante clientes HTTP asíncronos (`httpx`).<br>2. Implementar un patrón *Circuit Breaker* (Estado: *Closed*, *Open*, *Half-Open*) que abra el circuito tras 5 fallos consecutivos, respondiendo inmediatamente HTTP `503 Service Unavailable` sin saturar la red. | **Mitigado por arquitectura en memoria:** Al ejecutarse en el mismo proceso, la consulta es en memoria. <br>*Plan distribuido:* Configuración de timeouts en adaptadores HTTP de infraestructura. |
| **2. Responde Tarde (Alta Latencia / Congestión)** | La consulta de verificación de producto experimenta latencias anómalas ($> 1.5\text{ s}$) debido a saturación en el servidor o contención de recursos. | Degradación severa del tiempo de respuesta en el registro de salidas, haciendo que las peticiones concurrentes acumulen cola en el *event loop* y superen el umbral de $p95 \le 400\text{ ms}$. | **Exclusión Mutua con Límite de Espera + Liberación Limpia:** <br>Uso de corrutinas con tiempo de espera acotado (`asyncio.wait_for`) sobre la adquisición del lock de SKU. Si la respuesta excede el tiempo tolerable, se aborta la transacción y se libera el cerrojo sin corromper el stock. | **Implementado:** Manejo asíncrono nativo en FastAPI (`app/main.py`) y control de concurrencia mediante `asyncio.Lock()` por SKU (`app/inventario/`). |
| **3. Responde Dos Veces (Duplicidad por Reintentos)** | Un cliente o red reintenta un registro de movimiento (`POST /inventario/{sku}/salidas`) tras un fallo de conexión temporal, enviando dos veces la misma instrucción de descuento. | Riesgo de **doble descuento de stock** sobre el mismo producto, generando quiebres de inventario o inconsistencias graves en el saldo. | **Idempotencia Transaccional + Clave de Idempotencia (*Idempotency Key*):** <br>1. Exigir la cabecera HTTP `X-Idempotency-Key` en operaciones mutativas de inventario.<br>2. Registrar en una caché volatil los identificadores de transacciones procesadas. Si llega una petición duplicada con la misma clave, se retorna la respuesta almacenada previamente sin reejecutar la reducción de stock. | **Implementado por serialización:** La exclusión mutua por SKU en el caso de uso (`app/inventario/application/registrar_movimiento.py`) atiende atómicamente las peticiones, garantizando consistencia estricta en el orden de descuento. |

---

## 3. Anexo de Riesgos y Deuda Técnica (arc42 §11)

Se actualiza la **Sección 11 del documento arc42 (`docs/arc42/arc42-template-EN.md`)** para formalizar el análisis de fallos distribuidos:

```markdown
### 11.3 Fallos Parciales en Integraciones Distribuidas
- **Mitigación de Latencia y Bloqueo:** El sistema previene bloqueos en cascada mediante llamadas asíncronas y timeouts acotados en los adaptadores cruzados entre módulos (`ADR-0003`).
- **Garantía de Idempotencia:** La serialización de transacciones sobre el mismo SKU (`ADR-0002`) garantiza la atomicidad de las operaciones de inventario, mitigando inconsistencias por peticiones duplicadas.
- **Deuda de Redundancia:** Al mantenerse como Monolito Modular en memoria RAM (C5), los patrones distribuidos pesados (como Sagas orquestadas o Patrón Outbox) se evalúan como sobreingeniería injustificada en la etapa actual (ver `ADR-0010`).