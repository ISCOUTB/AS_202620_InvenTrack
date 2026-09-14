# Auditoría de Modularidad y Plan de Corrección — InvenTrack

**Propósito:** Evaluar la arquitectura interna del monolito modular frente a las reglas de Domain-Driven Design (DDD), identificando acoplamientos o violaciones de límites de dominio entre módulos y documentando su resolución formal mediante el **ADR-0003**.

---

## 1. Contexto de la Auditoría

En las primeras iteraciones del sistema, las reglas de negocio entre el catálogo de **Productos** y el stock de **Inventario** presentaban una desconexión en el flujo de datos:
1. Para cumplir con el escenario **ESC-02** (impedir la eliminación de un producto si tiene historial), el módulo de `productos` dependía de un doble de prueba estático (`in_memory_verificador_movimientos.py`) sin consultar el registro real de inventario.
2. El módulo de `inventario` permitía registrar entradas o salidas de stock sobre cualquier `producto_id`, sin validar si el ítem realmente existía o estaba activo en el catálogo.

---

## 2. Violaciones Detectadas en el Código Actual

### **Violación VIO-01: Verificación de Movimientos y Falta de Validación Cruzada Real**
* **Ubicación:** `app/productos/infrastructure/in_memory_verificador_movimientos.py`[cite: 2]
* **Síntoma:** `productos` intentaba resolver reglas sobre el historial de movimientos usando simuladores aislados o acoplándose conceptualmente a estructuras de inventario[cite: 2].
* **Causa Raíz:** Ausencia de un contrato de comunicación formal e inversión de dependencias entre la capa de aplicación de `productos` y la de `inventario`[cite: 2].
* **Riesgo:** Inconsistencia de datos, acoplamiento directo entre capas internas de distintos módulos e imposibilidad de extraer `productos` o `inventario` a microservicios independientes a futuro[cite: 2].

---

## 3. Plan de Corrección Aplicado (Resolución con ADR-0003)

Para solucionar la violación VIO-01 sin romper la regla de **Dueño Único de Datos** ni invadir los límites del dominio, se aplicó el patrón de **Puertos de Aplicación y Adaptadores Hexagonales**:

1. **Definición de Puertos de Aplicación:**
   * Se creó el puerto `ConsultarHistorialMovimientos` en la capa `application` de `inventario`.
   * Se creó el puerto `ConsultarProducto` en la capa `application` de `productos`.

2. **Implementación de Adaptadores Desacoplados en Infraestructura:**
   * En `productos/infrastructure/` se implementó `HistorialMovimientosAdapter`, el cual consume la capa de aplicación de `inventario` sin tocar sus entidades internas ni su base de datos directamente.
   * En `inventario/infrastructure/` se implementó `ValidadorDeProductoAdapter`, el cual consulta el estado del producto antes de autorizar escrituras de stock.

---

## 4. Matriz Trazable de Violaciones y Estado

| ID | Módulo Afectado | Violación Detectada | Causa Raíz | Plan de Corrección / Solución Aplicada | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **VIO-01** | `app/productos` / `app/inventario` | Verificación de movimientos simulada y falta de validación de catálogo en stock[cite: 2]. | Falta de puertos de aplicación entre las capas internas del monolito[cite: 2]. | Implementación de comunicación bidireccional vía puertos de aplicación y adaptadores (`ADR-0003`). | **Resuelto (Commit `50dda5e`)** |
| **VIO-02** | `app/usuarios` | Módulo declarado en el mapa de contexto pero sin implementación de código. | Funcionalidad diferida para siguientes iteraciones (ESC-05). | Se mantiene como contexto del dominio desacoplado hasta su desarrollo. | **Pendiente por Diseño** |