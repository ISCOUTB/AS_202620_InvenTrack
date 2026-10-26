# ADR-0014: Selección del Almacenamiento In-Memory, Inmutabilidad de Movimientos y Cuantificación del Costo de Reversión

- **Estado:** Aceptado
- **Contexto:** Tercer Corte (Arquitectura de Datos, Límites de Contenedores y Costos de Deuda Técnica)
- **Sistema:** InvenTrack — Monolito Modular
- **Componentes Afectados:** Capa de Persistencia de Módulos (`inventario`, `productos`, `usuarios`, `proveedores`).

---

## 1. Contexto y Problema

Una de las decisiones de datos más críticas y **costosas de revertir** a largo plazo en la arquitectura de un sistema es la elección del mecanismo de almacenamiento primario y el modelo de mutación de datos. 

En InvenTrack, el MVP utiliza **Repositorios en Memoria RAM (estructuras de datos en Python)** encapsulados por módulo y un modelo **Append-Only inmutable para los movimientos de inventario** (los registros de entrada y salida solo se insertan, nunca se sobreescriben ni borran).

Se evalúa el impacto técnico, el esfuerzo de refactorización y los costos asociados en caso de requerir una reversión hacia una base de datos relacional (SQL) persistente en producción.

---

## 2. Decisión Arquitectónica

Se decide **mantener los repositorios en memoria RAM como almacenamiento primario temporal del MVP**, aplicando el patrón **Append-Only** para los movimientos de inventario y protegiendo el acceso mediante **Puertos y Adaptadores (Arquitectura Hexagonal)**. 

Ningún caso de uso accede directamente a las estructuras globales de almacenamiento, restringiendo la dependencia exclusivamente a los adaptadores de infraestructura (`app/<modulo>/infrastructure/`).

---

## 3. Análisis de Opciones y Cuantificación Explícita del Esfuerzo de Reversión

### Opción A: Mutación In-Place con Base de Datos Relacional Directa (Descartada para el MVP)
* **Descripción:** Conectar desde el inicio los casos de uso directamente a un ORM relacional y sobreescribir el stock actual en una tabla compartida.
* **Costo y Riesgo:** Acoplamiento extremo y dificultad para aislar contextos en el monolito modular.

### Opción B: Persistencia en Memoria RAM con Repositorios Hexagonales (Opción Seleccionada)
* **Descripción:** Abstracción estricta mediante interfaces de repositorio en memoria RAM para garantizar costo cero ($0.00 USD) y velocidad de ejecución en el MVP.
* **Cuantificación del Costo de Reversión:**
  1. **Esfuerzo de Refactorización Estimado:** Cambiar la capa de repositorios en memoria RAM actual hacia un ORM relacional persistente (ej. PostgreSQL con SQLAlchemy) requerirá implementar 4 adaptadores SQL nuevos. Se estima un esfuerzo técnico de **120 a 160 horas-hombre**.
  2. **Impacto en Migración de Datos:** Los repositorios RAM no persisten datos al reiniciar el contenedor; la migración requiere diseñar scripts de *seeding* inicial para catálogos.
  3. **Mitigación del Riesgo:** Al haber diseñado el sistema con Arquitectura Hexagonal y contratos de interfaz por módulo, la reversión/migración se limita a reemplazar los adaptadores de la capa de infraestructura, **sin necesidad de reescribir la lógica de negocio ni los casos de uso en el dominio**.