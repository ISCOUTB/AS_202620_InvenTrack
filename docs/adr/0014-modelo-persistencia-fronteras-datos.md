# ADR-0014: Selección del Modelo de Persistencia Encapsulada y Fronteras de Datos en el Monolito Modular

- **Estado:** Aceptado
- **Contexto:** Tercer Corte (Decisiones Arquitectónicas Críticas y Costo de Reversión)
- **Sistema:** InvenTrack — Monolito Modular
- **Componentes Afectados:** Capas de persistencia de los módulos de `Inventario`, `Productos`, `Usuarios` y `Proveedores`.

---

## 1. Contexto y Problema

En el diseño de sistemas de software empresarial, una de las decisiones más intensivas en datos y **más costosas de revertir a largo plazo** es la definición de las fronteras de almacenamiento y el acoplamiento de los modelos de persistencia. 

En InvenTrack, nos enfrentamos a la disyuntiva de elegir entre:
1. Una base de datos relacional monolítica compartida (*Shared Database*).
2. Un modelo de persistencia estrictamente encapsulado por módulo (*Database-per-Module / Repository Pattern in Memory*) dentro de un monolito modular.

Cambiar esta decisión en una etapa avanzada del proyecto implica reescribir la lógica de acceso a datos, manejar transacciones distribuidas (Sagas de dos fases) y lidiar con la migración masiva de esquemas relacionales interconectados, lo cual representa un riesgo crítico de pérdida de datos e inconsistencia.

---

## 2. Decisión Arquitectónica

Se decide **adoptar un modelo de persistencia estrictamente encapsulado a nivel de límites de módulo (*Bounded Context Persistence*)**, donde cada módulo (`inventario`, `productos`, etc.) gestiona sus propios repositorios de datos y modelos de dominio de forma aislada, prohibiendo el acceso directo a las tablas o estructuras de almacenamiento de otros módulos. 

Cualquier colaboración de datos entre módulos debe realizarse exclusivamente a través de puertos de aplicación explícitos o contratos de eventos asíncronos.

---

## 3. Opciones Evaluadas

### Opción A: Base de Datos Relacional Compartida (*Shared Database*)
* **Descripción:** Todos los módulos del monolito consultan y escriben sobre el mismo esquema de base de datos relacional y las mismas tablas maestras.
* **Ventajas:** Simplicidad inicial para realizar *joins* directos entre tablas (ej. unir stock de inventario con datos de productos en una sola sentencia SQL) y menor fricción en consultas complejas.
* **Desventajas (Costo Prohibitivo de Reversión):** Acoplamiento de base de datos extremo. Si en el futuro se requiere extraer un módulo a un microservicio independiente, separar las tablas compartidas y las llaves foráneas cruzadas resulta extremadamente costoso, propenso a errores y genera una fuerte deuda técnica estructural.

### Opción B: Persistencia Encapsulada por Módulo (Opción Seleccionada)
* **Descripción:** Aislamiento total de los datos por módulo. El módulo de inventario solo conoce identificadores planos de productos (`sku`), validando su existencia mediante adaptadores y contratos de puerto.
* **Ventajas:** Facilita una futura evolución hacia microservicios con cero fricción en la capa de datos, previene efectos colaterales imprevistos y protege la integridad de los contextos delimitados.
* **Desventajas:** Requiere mayor disciplina en el diseño de contratos de comunicación y evita los *joins* relacionales directos entre dominios dispares.

---

## 4. Consecuencias y Compensaciones (*Trade-offs*)

1. **Costo de Reversión Neutralizado:** Al mantener los datos estrictamente encapsulados por módulo desde el diseño inicial, se elimina la barrera técnica más pesada en caso de requerir una extracción física a microservicios en el futuro.
2. **Consistencia por Contratos:** Se traslada la responsabilidad de la integridad de los datos a la validación en los adaptadores de aplicación y al versionamiento riguroso de contratos de eventos.
3. **Complejidad de Consultas Cruzadas:** Se asume el costo de realizar consultas compuestas mediante orquestadores de aplicación en memoria en lugar de depender de restricciones relacionales de base de datos a nivel de motor.