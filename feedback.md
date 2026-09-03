# Feedback de revisión — InvenTrack

Este documento compara las observaciones publicadas en el repositorio de feedback con la evolución real del repositorio `AS_202620_InvenTrack`.

La revisión se realizó teniendo en cuenta:

* El **hash exacto calificado** en cada semana.
* La **fecha y hora de cierre** de cada entrega.
* Los commits realizados antes y después de cada cierre.
* El estado actual del repositorio únicamente para identificar correcciones posteriores.
* La diferencia entre:

  * una observación incorrecta del feedback, y
  * una observación correcta que posteriormente fue corregida por el equipo.

> **Criterio utilizado:** si una corrección fue realizada después del cierre de una semana, no se considera un error del feedback de esa semana. La entrega debe evaluarse con el estado que existía al momento del cierre.

---

# Semana 1 — Equipo, problema y repositorio

## Resultado de la comparación

### El feedback de la semana fue correcto.

Las observaciones del feedback indicaban que faltaban:

* Las dos tensiones de calidad enfrentadas en la ficha.
* La tabla de ocho columnas en `docs/aspectos.md`.
* La estructura versionada de:

  * `docs/arc42/`
  * `docs/adr/`
  * `docs/c4/`
* Evidencia de contribución de todos los integrantes.

Estas observaciones correspondían al estado real del repositorio en ese momento.

Posteriormente varias de estas observaciones fueron corregidas durante las semanas siguientes, pero esos cambios no existían en el estado de cierre de S1.

## Conclusión Semana 1

> **El feedback fue correcto para el estado entregado en Semana 1.**

No se identifican criterios marcados incorrectamente como incumplidos debido a que las correcciones aparecieron posteriormente.

---

# Semana 2 — Escenarios de calidad y restricciones

## Resultado de la comparación

### El feedback de la semana fue correcto.

El feedback reconoció correctamente como cumplidos:

* Secciones 1, 2, 3 y 10 de arc42.
* Restricciones clasificadas y justificadas.
* Diferenciación entre requisitos y restricciones.
* Escenarios de calidad.
* Medidas verificables.
* Árbol de utilidad.
* C4 Nivel 1.
* Registro de IA actualizado.
* Estructura mínima del repositorio.

También señaló dos detalles que posteriormente fueron corregidos:

### `docs/adr/README.md`

El archivo placeholder no cumplía realmente la convención esperada para los ADR.

Posteriormente fue eliminado.


### `docs/aspectos.md`

El feedback indicó que todavía estaba en formato de prosa y no en la tabla de ocho columnas requerida.

Posteriormente, en Semana 3, se convirtió a la estructura:

```text
ID → Aspecto → Requisito → C4 → ADR → Código → Pruebas → Evidencia
```

## Conclusión Semana 2

> **El feedback estuvo correcto.**

Los elementos señalados como pendientes fueron corregidos posteriormente, pero no existían todavía en el estado calificado de la semana.

---

# Semana 3 — Estrategia de solución y primer ADR

## Resultado de la comparación

### El feedback de la semana fue correcto.

Además, la revisión confirma que no hubo commits tardíos después del cierre.

El feedback reconoció correctamente:

* ADR-0001 creado.
* Contexto arquitectónico.
* Alternativas evaluadas.
* Decisión arquitectónica.
* Consecuencias.
* Matriz comparativa.
* Esqueleto ejecutable.
* Paquetes coherentes con el estilo.
* Prueba automatizada.
* Pipeline CI en verde.
* Enlaces desde `aspectos.md`.
* Enlace desde ESC-01.
* Registro de IA actualizado.

Posteriormente, el ADR fue actualizado para reflejar su aceptación.

## Conclusión Semana 3

> **El feedback estuvo correcto.**

La observación sobre el estado del ADR no fue un error del revisor: la aceptación ocurrió posteriormente.

---

# Feedback — Semana 4

## Revisión del feedback

Al comparar el feedback publicado con el estado real de los archivos existentes antes de la fecha límite, se encontraron algunas observaciones correctamente identificadas y otras que deben corregirse.

### Correcciones al feedback

#### arc42 — Secciones 4, 5, 6 y 9

El feedback indicó que las secciones:

* §4 — Solution Strategy.
* §5 — Building Block View.
* §6 — Runtime View.
* §9 — Architecture Decisions.

no estaban realizadas.

Sin embargo, estas secciones sí estaban presentes y desarrolladas en el archivo `docs/arc42/arc42-template-EN.md` correspondiente al estado previo a la fecha límite.

Por lo tanto, las observaciones de **No cumple** sobre estas secciones no coinciden con la evidencia disponible al momento del cierre.

---

#### C4 Nivel 2

El feedback marca como «No cumple» que el C4 Nivel 2 incluya una interfaz Web y una Base de Datos que todavía no existen como código. Sin embargo, el diagrama sí representa correctamente el API Backend existente y puede documentar contenedores arquitectónicos previstos para la solución, siempre que se indique explícitamente cuáles están implementados y cuáles corresponden a una arquitectura objetivo. Y en esta se menciona explicitamnete que: ambas están como "Por definir" porque el stack de frontend y de persistencia todavía no se ha decidido.

---

El resto de observaciones sí fueron correctamente identificadas, algunas de estas afectaron el reconocimiento de otros criterios, como en readme o en una parte del propio arc42 que se mencionaba como completa solo unas secciones del arc42. Actualmente se han ido corrigiendo algunas de estas observaciones


## Conclusión

El feedback de la Semana 4 fue **parcialmente correcto**.

Se identificaron correctamente elementos que todavía estaban pendientes, especialmente:

* la fila del aspecto de calidad completa hasta Pruebas;
* la implementación y prueba del mecanismo de consistencia de datos;
* la evidencia de SonarCloud.

Sin embargo, deben corregirse las observaciones que indicaban como inexistentes o pendientes las secciones:

* §4 — Solution Strategy;
* §5 — Building Block View;
* §6 — Runtime View;
* §9 — Architecture Decisions;

ya que estas sí estaban presentes en el estado del proyecto antes de la fecha límite.

De igual forma, el C4 Nivel 2 sí existía y documentaba la arquitectura de contenedores, aunque algunos de estos todavía estuvieran pendientes de implementación o definición tecnológica.

La principal oportunidad de mejora del equipo para esta semana fue mantener sincronizada la documentación, especialmente el README, con el estado real de los demás artefactos del repositorio.