# Auditoría de Modularidad y Violaciones de Dominio

En esta auditoría se analizan los límites de los módulos frente a las reglas de Domain-Driven Design (DDD) y el plan de corrección aplicado mediante el **ADR-0003**.

---

## 1. Violaciones Detectadas en el Código Original

### **Violación VIO-01: Verificación de Movimientos desacoplada manualmente / Invasión de fronteras**
- **Ubicación:** `app/productos/infrastructure/in_memory_verificador_movimientos.py`
- **Síntoma:** El chequeo para evitar la eliminación de un producto con historial (`ESC-02`) se realizaba con un doble de pruebas estático en `productos` o requería inspeccionar datos de `inventario`.
- **Causa Raíz:** Falta de un contrato explícito mediante puertos de aplicación entre `productos` e `inventario`.
- **Riesgo:** Inconsistencia de datos entre el catálogo y los movimientos reales en bodega.

---

## 2. Plan de Corrección Aplicado (ADR-0003)

1. **Inversión de Dependencias (Hexagonal):**
   - Se crearon puertos en la capa `application` de cada módulo (`ConsultarProducto` en productos y `ConsultarHistorialMovimientos` en inventario).
2. **Uso de Adaptadores en Infraestructura:**
   - Se implementó `HistorialMovimientosAdapter` en `productos/infrastructure` para invocar el puerto de `inventario`.
   - Se implementó `ValidadorDeProductoAdapter` en `inventario/infrastructure` para validar la existencia del producto antes de registrar movimientos.

---

## 3. Matriz de Corrección de Violaciones

| ID | Módulo Afectado | Violación Detectada | Causa Raíz | Plan de Corrección Aplicado | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **VIO-01** | `app/productos` / `app/inventario` | Falta de validación cruzada real de datos entre productos y movimientos. | Ausencia de comunicación formal entre capas de aplicación. | Implementación de adaptadores de puerto cruzados (`ADR-0003`). | **Resuelto (Commit `50dda5e`)** |