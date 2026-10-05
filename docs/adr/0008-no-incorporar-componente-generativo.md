# ADR-0008: No incorporar un componente generativo al MVP

- **Estado:** Aceptado
- **Fecha:** 2026-10-04
- **Decisores:** Equipo InvenTrack

## Contexto

InvenTrack usa herramientas de IA como apoyo al desarrollo, pero el sistema
entregado no necesita generar texto, codigo, recomendaciones ni decisiones de
negocio durante su ejecucion. Los escenarios actuales se resuelven con reglas
deterministas de inventario, productos y observabilidad HTTP.

Incorporar un proveedor generativo tambien obligaria a resolver costo por
operacion, latencia, manejo de credenciales, evaluacion de calidad y limites de
los datos enviados a un tercero. Esas preocupaciones no son necesarias para
cumplir ESC-01, ESC-02 ni ESC-04 en el MVP.

## Opciones evaluadas

1. **Incorporar un proveedor LLM externo.** Se descarta porque agrega costo
   variable, latencia de red, secretos y una dependencia operativa sin un caso
   de uso requerido.
2. **Ejecutar un modelo local.** Se descarta porque agrega consumo de CPU y
   memoria incompatible con las restricciones actuales de despliegue y no
   aporta valor al alcance definido.
3. **No incorporar un componente generativo.** Se adopta; la asistencia de IA
   permanece como herramienta del proceso de desarrollo y no como dependencia
   ni funcionalidad del producto.

## Decision

Se acepta **no incorporar un componente generativo en el MVP**. No se agregan
clientes de APIs de modelos, modelos locales, prompts operativos ni rutas que
dependan de una respuesta generativa.

Por esta decision no aplica un conjunto de evaluacion de calidad generativa ni
una medicion de costo por operacion o latencia de inferencia. La latencia
operacional del sistema se evalua de forma determinista mediante ESC-04 y
ADR-0007.

## Consecuencias

- No hay costo, latencia ni disponibilidad adicional asociados a inferencia.
- No se introducen credenciales de proveedores generativos ni transferencia de
  datos del inventario a servicios externos.
- El producto mantiene comportamiento determinista y evaluable con pytest.
- La asistencia de IA usada para construir documentacion o codigo queda
  registrada en [docs/ia.md](../ia.md), pero no forma parte del runtime.
- Si aparece un caso de uso generativo, se debe crear un nuevo ADR o reemplazar
  esta decision con otra decision aceptada que incluya conjunto de evaluacion,
  costo por operacion, latencia, tratamiento de datos y gestion de secretos.

## Verificacion

El barrido de dependencias y del arbol versionado no encontro clientes o
referencias de runtime a proveedores generativos. Las dependencias actuales
estan declaradas en [requirements.in](../../requirements.in) y fijadas con
hashes en [requirements.txt](../../requirements.txt); ninguna es un cliente de
modelos generativos.

## Trazabilidad

- **Requisitos y restricciones:** ESC-01, ESC-02, ESC-04 y C5 costo cero.
- **Aspectos relacionados:** [ASP-01](../aspectos.md#asp-01--consistencia-de-datos),
  [ASP-03](../aspectos.md#asp-03--observabilidad-de-latencia).
- **Registro de IA:** [docs/ia.md](../ia.md), entrada del 2026-10-04.
- **Evidencia de seguridad y dependencias:**
  [evidencia-ia-corte-s6.md](../evidencia-ia-corte-s6.md#8-auditoria-de-erosion-y-verificaciones-de-seguridad).
- **Pruebas:** la suite pytest del proyecto verifica el comportamiento
  determinista; no existe prueba de inferencia porque el componente no se
  incorpora.
