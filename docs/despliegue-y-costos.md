# Guía de Despliegue, Observabilidad y Costos — InvenTrack

**Actualización posterior a S15.** El perfil durable añade un usuario y un rol por credencial, 401/403 en las rutas de negocio y persistencia transaccional de catálogo, stock, historial y auditoría con actor. Producción cerrada conserva el 503 preventivo. Las observaciones previas corresponden al perfil inicial. [ADR-0019](./adr/0019-autenticar-usuarios-y-autorizar-por-rol.md) · [ADR-0020](./adr/0020-persistir-inventario-y-auditoria-en-sqlite.md) · [verificación](./verificacion-final.md).

**Propósito:** Este documento evalúa las alternativas de despliegue para la API de InvenTrack, justificando la elección operativa según las restricciones de negocio (C5: Costo $0 y sin uso de tarjetas de crédito) y su impacto en los atributos de calidad (ESC-04: p95 $\le$ 400 ms), consolidando la evidencia de observabilidad y operación.

---

## 1. Pieza del Sistema y Alternativas Evaluadas

**Pieza seleccionada:** Contenedor de la API REST (Backend en FastAPI).

El servicio institucional construye el contenedor mediante `deploy/compose.lab.yaml` y publica la API en `inventrack.iscoutb.dev`.

La infraestructura Azure de `infra/` y `.github/workflows/deploy.yml` queda descartada
como artefacto histórico; el workflow está desactivado y no participa en la publicación.

---

## 2. Estado de la Evidencia e Infraestructura

| Evidencia | Implementación | Estado / Dato a Registrar |
|---|---|---|
| **URL Pública Externa** | Dokploy, HTTPS | `https://inventrack.iscoutb.dev` |
| **Infraestructura como Código** | `deploy/compose.lab.yaml` y `Dockerfile` | Versionada; Terraform en `infra/` queda como alternativa Azure exploratoria no utilizada |
| **Pipeline CI/CD** | GitHub Actions + autodespliegue Dokploy | GitHub Actions valida la suite; Dokploy publica desde `main` según su configuración |
| **Health Check** | `GET /health` | Configurado en Dokploy; la comprobación vigente documentada es la de Dokploy en S13 |
| **Logs Estructurados** | JSON por línea en `stdout` | Evento `http_request`, sin credenciales ni cuerpos sensibles |
| **Métrica Consultable** | `GET /metrics` | Formato Prometheus; acceso local o con token interno en producción |
| **Protección de Secretos** | `.env` ignorado y secretos de GitHub | No hay credenciales de ambiente en la rama pública |
| **Run Exitoso** | Dokploy + GitHub Actions | `GET /health` responde 200 en el dominio institucional; la suite se ejecuta en GitHub |

---

## 3. Observabilidad y Prueba Externa

Desde una red externa (doméstica o móvil), ejecutar:

```powershell
# Dokploy institucional (health público; métricas con token interno en producción)
curl.exe --fail https://inventrack.iscoutb.dev/health
curl.exe --fail -H "X-Internal-Token: <TOKEN_GESTIONADO>" https://inventrack.iscoutb.dev/metrics

```

En el dominio institucional, `/health` debe responder:

```json
{"status":"ok","service":"InvenTrack"}
```

Con el token interno válido, `/metrics` contiene, como mínimo, las series
`inventrack_http_requests_total` y
`inventrack_http_request_duration_seconds_total`.

La comprobación fechada histórica de Dokploy está en
[evidencia-seguridad-s13.md](evidencia-seguridad-s13.md): `/health` respondió
`200`, las superficies internas sin token respondieron `404` y las rutas de
negocio respondieron `503` por bloqueo preventivo. No se registra el token real
en documentación.

El CI de la punta actual `e17afb8ad59fba8c851e06338c1219f7f4bc918f` terminó
exitosamente en el
[run 42319774632](https://github.com/ISCOUTB/AS_202620_InvenTrack/actions/runs/42319774632).
Este resultado no acredita redespliegue ni permite verificar `/metrics` sin el
token gestionado por la plataforma; esas comprobaciones quedan como
actividades externas.

---

## 4. Contraste: Arranque en Frío (Cold Start) vs. Escenario de Calidad (p95)

* **El Requisito (ESC-04):** El 95% de las peticiones concurrentes ($p95$) deben resolverse en $400\text{ ms}$ o menos.
* **Dokploy:** El servidor institucional mantiene el servicio gestionado por el panel,
	sujeto a la cuota compartida del equipo.
* **Comportamiento en caliente:** En el dominio institucional, las transacciones procesadas en
	memoria se ejecutan en $< 50\text{ ms}$ según la medición del proyecto.

---

## 5. Estimación Mensual de Costos y Punto de Quiebre

### Estimación Inicial (MVP)

| Magnitud | Supuesto Mensual | Cómo se Obtiene |
|---|---:|---|
| **Operaciones** | 50,000 peticiones | 25 negocios piloto $\times$ 2,000 peticiones |
| **Datos Almacenados** | 0.10 GB | Catálogo y movimientos MVP (repositorio *in-memory*) |
| **Tráfico de Salida** | 1.00 GB | Respuestas JSON pequeñas (~20 KB por petición) |
| **Tiempo de Ejecución** | 10,000 s (~2.78 h) | 50,000 invocaciones $\times$ 0.2 s respuesta media |

### Costo Monetario
* **Dokploy institucional:** $0.00 USD/mes para el equipo; cuota de 512 MB y 0.5 CPU por contenedor.
* **GitHub Actions:** $0.00 USD/mes (Repositorio público).
* **Total Monetario:** **$0.00 USD/mes**.

### Punto de Quiebre (*Breaking Point*)
El modelo gratuito se romperá bajo cualquiera de las siguientes condiciones:
1. **Agotamiento de Memoria (OOM):** El catálogo e historial *in-memory* no deben superar la memoria disponible en el destino usado: 256 MB para el contenedor de la API en Dokploy.
2. **Cuota de CPU o compilación:** En Dokploy el equipo no debe superar 0.5 CPU por contenedor ni la memoria compartida durante el build.
3. **Persistencia:** Si la pérdida de datos en memoria deja de ser aceptable, se requiere persistencia durable; [ADR-0012](adr/0012-mantener-repositorios-en-memoria-en-el-mvp.md) establece evaluar primero una base relacional compartida mediante adaptadores por módulo.

---

## 6. Procedimiento de Reversión (Rollback)

### Dokploy institucional

1. Ejecutar `git revert <commit-con-fallo>` en `main`.
2. Esperar la validación de GitHub Actions.
3. Dokploy reconstruirá el servicio `sistema` desde `./deploy/compose.lab.yaml`.
4. Confirmar `https://inventrack.iscoutb.dev/health` y revisar los logs del despliegue.

---

## 7. Trazabilidad Arquitectónica

El [ADR-0006](adr/0006-desplegar-en-dokploy-institucional.md) documenta la incorporación de Dokploy. El [ADR-0024](adr/0024-usar-solo-dokploy-institucional.md) lo establece como único destino.
