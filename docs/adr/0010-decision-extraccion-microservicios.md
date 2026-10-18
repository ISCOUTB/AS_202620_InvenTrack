# ADR-0010: Evaluación y Decisión de No Extraer el Módulo de Inventario a Microservicio Independiente

- **Estado:** Aceptado
- **Fecha:** 2026-10-18
- **Contexto:** Semana 11 · Tercer Corte (Sistemas Distribuidos y Microservicios)
- **Decisores:** Equipo de Arquitectura InvenTrack (ISCOUTB)

---

## 1. Contexto y Problema

Durante el análisis de evolución del Monolito Modular (`ADR-0001`) y el estudio de patrones de computación orientada a servicios y microservicios (basado en Sam Newman, *Building Microservices*), se evaluó la posibilidad de extraer el módulo de `inventario` (responsable del control de concurrencia y stock bajo `ADR-0002`) para convertirlo en un microservicio autónomo desplegado de forma independiente y comunicado a través de la red.

La pregunta de diseño a resolver es: **¿Conviene en la etapa actual del MVP extraer el módulo de inventario a un servicio independiente?**

---

## 2. Opciones Evaluadas

1. **Opción A: Extraer el módulo `inventario` a un Microservicio independiente.**
   - Desacoplar físicamente el módulo `inventario` del proceso principal.
   - Exponer su funcionalidad a través de HTTP/gRPC.
   - Asignarle un almacén de datos independiente (*Database per Service*).

2. **Opción B: Mantener el módulo dentro del Monolito Modular con límites estrictos de contexto (No Extraer).**
   - Conservar el despliegue unificado de la aplicación en FastAPI.
   - Mantener el aislamiento lógico mediante Arquitectura Hexagonal y puertos de aplicación consumidores/proveedores (`ADR-0003`).

---

## 3. Decisión Adoptada

Se selecciona la **Opción B: No Extraer el módulo de inventario**, manteniendo InvenTrack como un Monolito Modular estructurado.

---

## 4. Criterios Técnicos de Argumentación

La decisión de **NO extraer** se fundamenta en los siguientes criterios de ingeniería de software:

1. **Evitar la sobreingeniería de Transacciones Distribuidas (Sagas / Outbox):**
   - Extraer `inventario` obligaría a coordinar las operaciones entre `productos` e `inventario` a través de la red.
   - Cualquier movimiento de stock requeriría implementar patrones de consistencia eventual complejos (como *Sagas orquestadas/coreografiadas* o *Patrón Outbox*), introduciendo puntos de fallo por latencia de red, reintentos e inconsistencias temporales sin una necesidad de negocio real.

2. **Cumplimiento estricto de la restricción de costo cero (C5):**
   - Mantener servicios separados incrementa el consumo de memoria RAM y la necesidad de orquestación de contenedores adicionales.
   - El modelo unificado en memoria permite operar al 100% dentro de la capa gratuita de Render y Dokploy ($0.00 USD), satisfaciendo la restricción **C5**.

3. **Inexistencia de carga diferenciada que justifique escalamiento independiente:**
   - La carga actual del sistema (validada en el experimento del S10 con 20 req/s y $p95 = 28\text{ ms}$) es absorbida holgadamente por el proceso único mediante exclusión mutua asíncrona (`asyncio.Lock`).
   - No existe una disparidad de tráfico ni de equipo de desarrollo que justifique la sobrecostosa frontera de red de un microservicio.

4. **Preservación de la opción de extracción futura (Strangler Pattern):**
   - Gracias al diseño de Arquitectura Hexagonal (`ADR-0001` y `ADR-0003`), los dominios están desacoplados mediante puertos. Si en el futuro el volumen de datos o el crecimiento del equipo exige la extracción, esta se podrá realizar de forma limpia aplicando el *Strangler Fig Pattern* sin reescribir la lógica de negocio.

---

## 5. Consecuencias

### Positivas:
- Se preserva la atomicidad transaccional y la latencia ultra-baja en memoria ($p95 = 28\text{ ms}$).
- Cero complejidad de red, fallos en cascada o serialización entre servicios.
- Mantenimiento del costo operativo en $0.00 USD (C5).

### Negativas / Deuda Asumida:
- El escalamiento del módulo de inventario sigue acoplado al proceso global del monolito (deuda técnica aceptada y registrada en arc42 §11).

---

## 6. Referencias
- Newman, S. *Building Microservices* (Caps. 1–3: boundaries and monolith migration).
- `ADR-0001`: Monolito Modular con Hexagonal por módulo.
- `ADR-0003`: Integración entre productos e inventario vía puertos de aplicación.