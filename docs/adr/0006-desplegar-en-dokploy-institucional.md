# ADR-0006: Desplegar InvenTrack en Dokploy institucional

**Fecha:** 2026-09-29  
**Estado:** Aceptado  
**Complementa:** [ADR-0005: Elección de plataforma de despliegue](0005-eleccion-plataforma-despliegue.md)

## Contexto

El ADR-0005 seleccionó Render como plataforma PaaS para el despliegue productivo
con costo cero. Posteriormente al cierre de la semana 8, el equipo recibió acceso
al servidor institucional `iscoutb.dev`, cuyo panel Dokploy ya provisiona el
proyecto `inventrack` y el servicio Compose `sistema`. Este nuevo destino permite
operar la misma API en paralelo con Render.

El despliegue institucional debe respetar las restricciones del servidor:

- máximo de 512 MB de memoria por equipo;
- máximo de 0.5 CPU por contenedor;
- sin puertos publicados directamente desde Compose;
- secretos fuera del repositorio;
- persistencia mediante volúmenes nombrados si el sistema la requiere.

El MVP actual utiliza repositorios en memoria y solo necesita un contenedor API.

## Opciones evaluadas

### Opción A: Continuar usando Render

Render ya está configurado mediante `render.yaml`, ofrece HTTPS y despliegue desde
GitHub. Se mantiene como destino operativo independiente.

### Opción B: Desplegar también en Dokploy institucional

Dokploy consume `deploy/compose.lab.yaml` desde la rama `main`, asigna el dominio
`inventrack.iscoutb.dev` y permite consultar el sistema desde fuera de la red
universitaria. El Compose puede limitar el proceso a 256 MB y 0.5 CPU.

### Opción C: Activar el despliegue Azure histórico

Se descarta. El workflow `.github/workflows/deploy.yml` está desactivado y la
infraestructura Terraform de `infra/` fue conservada como artefacto histórico.
Reactivarla exigiría credenciales y una suscripción que no cumple la restricción
C5.

## Decisión

Se acepta **Dokploy institucional como segundo destino operativo**, incorporado
después del cierre de la semana 8, y se mantiene Render como destino operativo
independiente según el ADR-0005. Ambos destinos construyen el mismo `Dockerfile` y
exponen la misma API FastAPI; ninguno reemplaza al otro.

La definición de Dokploy se versiona en
[`deploy/compose.lab.yaml`](../../deploy/compose.lab.yaml):

- servicio Compose: `api`;
- contexto de build: raíz del repositorio;
- puerto interno: `10000`;
- healthcheck: `GET /health`;
- límite: 0.5 CPU y 256 MB;
- dominio: `https://inventrack.iscoutb.dev`.

El panel Dokploy configura el servicio `sistema`, el Compose Path
`./deploy/compose.lab.yaml`, HTTPS con Let's Encrypt y el dominio apuntando al
servicio `api` en el puerto `10000`.

## Consecuencias

### Positivas

- URL pública institucional verificable: `https://inventrack.iscoutb.dev`.
- Infraestructura reproducible y versionada con Docker Compose.
- Health check, Swagger y métrica Prometheus accesibles externamente.
- Cumplimiento de la cuota institucional sin agregar base de datos al MVP.
- Despliegue automático desde `main` después de cada push.

### Negativas y mitigaciones

- Los datos son volátiles porque los repositorios son en memoria; reiniciar o
  escalar el contenedor pierde el estado. La migración a PostgreSQL requiere otro
  cambio arquitectónico.
- La cuota de 512 MB es compartida por el equipo. El límite de 256 MB del API
  deja margen para otros servicios futuros.
- Dokploy no sustituye las pruebas de GitHub Actions: el despliegue automático
  puede publicar un commit que todavía no haya sido validado por CI. Para una
  política de publicación controlada se debe usar una rama protegida de release.
- El servicio institucional no ofrece una copia de seguridad garantizada para
  este MVP; los datos de demostración deben poder recrearse mediante pruebas o
  seed cuando exista persistencia.

## Costos y punto de quiebre

El costo monetario directo para el equipo es **$0 USD/mes**, porque el servicio
forma parte del servidor institucional. La capacidad asignada está limitada a
512 MB por equipo y 0.5 CPU por contenedor.

El punto de quiebre se alcanza cuando el proceso, la compilación o servicios
adicionales requieren más de la cuota asignada, o cuando la pérdida de datos en
memoria deja de ser aceptable. En ese momento se debe migrar persistencia a una
base de datos y registrar un nuevo ADR con la capacidad y costos resultantes.

## Trazabilidad

- **Requisitos:** C5 costo cero; ESC-04 latencia p95 menor o igual a 400 ms en
  estado caliente; disponibilidad de una URL pública y health check.
- **C4/arc42:** [Deployment View, sección 7](../arc42/arc42-template-EN.md#7-deployment-view).
- **Código:** [Dockerfile](../../Dockerfile), [Compose institucional](../../deploy/compose.lab.yaml),
  [health y métricas](../../app/main.py).
- **Implementación:** commit [`417cb69`](https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/417cb69),
  que incorporó el Compose y la documentación inicial de `iscoutb.dev`; la
  actualización documental posterior queda en [`f9851ba`](https://github.com/ISCOUTB/AS_202620_InvenTrack/commit/f9851ba).
- **Pruebas:** [test_health.py](../../tests/test_health.py), pruebas de contrato y
  suite de GitHub Actions.
- **Evidencia externa:** `GET https://inventrack.iscoutb.dev/health`,
  `GET /metrics` y `GET /docs`, verificados el 2026-09-29.
- **Decisión relacionada:** ADR-0005 conserva la alternativa Render y no se
  reescribe porque el contrato del repositorio prohíbe modificar ADR aceptados.
