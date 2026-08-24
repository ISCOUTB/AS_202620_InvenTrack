# Uso de IA en el Proyecto

Este documento registra el uso de herramientas de inteligencia artificial durante el
desarrollo del proyecto, con fines de transparencia académica. Para cada uso se registra
para qué se usó, qué herramienta, qué se aceptó y **qué se rechazó y por qué** — esta
última columna es la que se revisa primero, porque es la que muestra criterio propio del
equipo, no solo el resultado que dio la IA.

## Herramienta(s) utilizadas

- Claude (Anthropic)
- ChatGPT (OpenAI)
- GitHub Copilot (Microsoft)

## Registro de uso

| Fecha | Etapa | Uso dado (qué se aceptó) | Rechazado / motivo | Nivel de intervención |
|-------|-------|---------------------------|----------------------|------------------------|
| 2026-08-08 | Definición del problema (S1) | Lluvia de ideas de dominios de proyecto (universitarios y externos), evaluación de viabilidad e impacto real de la idea de inventarios propuesta por el equipo, y redacción asistida de la ficha del problema y el aspecto de calidad declarado. | Las primeras versiones de la ficha y de la justificación del aspecto no convencieron al equipo por ser demasiado genéricas; se pidieron varias reescrituras hasta llegar a una versión que reflejara el problema real de las PYMEs de Cartagena y no una descripción abstracta de "sistema de inventarios". | Apoyo en ideación y redacción; las decisiones finales (elección del tema y del aspecto) fueron tomadas por el equipo. |
| 2026-08-16 | Escenarios de calidad y restricciones (S2) | Apoyo en ideas y redacción para las secciones del arc42 (objetivos, restricciones, contexto, requisitos de calidad); ayuda más puntual en la construcción del árbol de utilidad y del diagrama C4 de contexto. Se consultó a Claude y a ChatGPT en paralelo, comparando también apoyo de código. | Se rechazó la primera versión de los escenarios de calidad porque combinaba Artefacto y Entorno en una sola parte (5 partes en vez de 6), sin seguir el formato exacto visto en clase. Se rechazó también dejar "Seguridad" solo como meta de calidad sin escenario propio, pese a estar declarada como atributo priorizado — se le exigió a la IA formular ESC-05 para cerrar ese hueco. | El equipo revisó cada entrega contra las diapositivas de clase y decidió qué versión conservar cuando hubo más de una propuesta (por ejemplo, del diagrama de contexto). Los datos del equipo (nombres) y la decisión final sobre prioridades, atributos y umbrales quedan a cargo del equipo. |
| 2026-08-22 | Organización del repositorio y esqueleto ejecutable (S3/S4) | Se utilizaron Claude y GitHub Copilot para organizar el repositorio, integrar la documentación de la entrega, estructurar el esqueleto ejecutable con FastAPI y ordenar los módulos vacíos de la arquitectura Monolito Modular con Hexagonal. | Las primeras propuestas de estructura de carpetas y de redacción del ADR fueron demasiado genéricas o no calzaban del todo con las restricciones y escenarios ya declarados por el equipo; se pidieron varias iteraciones hasta que la matriz comparativa y el ADR quedaran evaluados específicamente contra los escenarios ESC-01 a ESC-05 del propio proyecto, en vez de argumentos genéricos de manual. | Apoyo en organización, redacción y estructuración técnica. El equipo revisó los archivos, confirmó el alcance sin lógica de negocio y mantuvo la responsabilidad sobre las decisiones finales de arquitectura y sobre la entrega. |

## Criterio del equipo sobre el uso de IA

El equipo usa IA como apoyo para acelerar tareas de redacción, exploración de alternativas
y estructuración de documentación, pero las decisiones de arquitectura, alcance y diseño
del sistema son discutidas y validadas por el equipo antes de implementarse. Cuando una
sugerencia de la IA no sigue el formato o el criterio visto en clase, se rechaza y se pide
una corrección — eso queda registrado en la columna "Rechazado / motivo" de la tabla de
arriba, no solo mencionado de forma general.

> Este documento se irá actualizando a lo largo del proyecto conforme se use IA en nuevas
> etapas (diseño, código, pruebas, documentación).