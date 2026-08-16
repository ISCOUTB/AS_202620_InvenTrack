# Árbol de Utilidad — InvenTrack

## 1. Propósito

El árbol de utilidad de **InvenTrack** organiza y prioriza los atributos de calidad que
condicionan la arquitectura del sistema. Su objetivo es transformar las preocupaciones
de los interesados en escenarios de calidad concretos y verificables.

La estructura utilizada es:

**Utilidad → Atributo de calidad → Refinamiento → Escenario de calidad**

Cada escenario se prioriza mediante dos dimensiones:

- **Impacto en el negocio:** qué tan grave sería para la operación de la PYME que el
  escenario no se cumpla.
- **Riesgo técnico:** qué tan difícil o incierto resulta para el equipo garantizar el
  escenario mediante una solución técnica.

La prioridad se expresa como:

**(Impacto en el negocio, Riesgo técnico)**

donde:

- **H = Alto**
- **M = Medio**
- **L = Bajo**

Los escenarios con mayor impacto y/o riesgo técnico son los que deben orientar primero
las decisiones arquitectónicas del proyecto.

---

## 2. Utilidad general del sistema

La utilidad principal de **InvenTrack** es proporcionar a pequeñas y medianas empresas
una fuente centralizada y confiable de información sobre su inventario, permitiendo
registrar y consultar movimientos de mercancía, controlar usuarios y detectar
oportunamente niveles bajos de stock.

La utilidad del sistema se relaciona directamente con el problema identificado en la
ficha del proyecto: descuadres de stock, quiebres de inventario, falta de trazabilidad
y dependencia de registros manuales o de una sola persona.

Por esta razón, la arquitectura debe priorizar especialmente la **integridad de los
datos**, la **continuidad operativa**, la **protección de la información** y una
respuesta suficientemente rápida para las operaciones diarias.

---

## 3. Árbol de utilidad

```mermaid
graph LR

    U[["Utilidad de InvenTrack<br/>Información de inventario confiable y disponible"]]

    U --> QA1(["Consistencia<br/>de datos"])
    U --> QA2(["Disponibilidad"])
    U --> QA3(["Rendimiento"])
    U --> QA4(["Seguridad"])

    QA1 --> R1(["Concurrencia en<br/>movimientos"])
    QA1 --> R2(["Integridad del<br/>historial y catálogo"])

    QA2 --> R3(["Continuidad<br/>operativa"])

    QA3 --> R4(["Tiempo de respuesta<br/>en consultas"])

    QA4 --> R5(["Control de acceso<br/>por rol"])

    R1 --> S1["ESC-01<br/>Salida simultánea<br/>(H,H)"]
    R2 --> S2["ESC-02<br/>Producto con historial<br/>(M,M)"]
    R3 --> S3["ESC-03<br/>Caída durante operación<br/>(H,M)"]
    R4 --> S4["ESC-04<br/>Consulta en hora pico<br/>(M,L)"]
    R5 --> S5["ESC-05<br/>Acceso no autorizado<br/>(M,M)"]

    classDef root fill:#0d3b66,stroke:#082746,color:#ffffff,font-weight:bold
    classDef attr fill:#1168bd,stroke:#0b4884,color:#ffffff,font-weight:bold
    classDef refine fill:#3d5a80,stroke:#293e59,color:#ffffff
    classDef high fill:#c0392b,stroke:#7b271b,color:#ffffff,font-weight:bold
    classDef medium fill:#d68910,stroke:#8a5a0a,color:#ffffff,font-weight:bold
    classDef low fill:#5c5c5c,stroke:#3d3d3d,color:#ffffff,font-weight:bold

    class U root
    class QA1,QA2,QA3,QA4 attr
    class R1,R2,R3,R4,R5 refine
    class S1,S3 high
    class S2,S5 medium
    class S4 low
