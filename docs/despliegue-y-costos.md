# Guía de Despliegue, Observabilidad y Costos — InvenTrack

**Propósito:** Este documento evalúa las alternativas de despliegue para la API de InvenTrack, justificando la elección operativa según las restricciones de negocio (C5: Costo $0 y sin uso de tarjetas de crédito) y su impacto en los atributos de calidad (ESC-04: p95 $\le$ 400 ms), consolidando la evidencia de observabilidad y operación.

---

## 1. Pieza del Sistema y Alternativas Evaluadas

**Pieza seleccionada:** Contenedor de la API REST (Backend en FastAPI).

Se mantienen dos destinos operativos para la misma imagen de la API:
1. **Render Web Service (Free Tier):** destino PaaS operativo configurado mediante `Dockerfile` y `render.yaml`.
2. **Dokploy institucional:** segundo destino operativo, incorporado después del cierre de la semana 8, configurado mediante `deploy/compose.lab.yaml` y el dominio `inventrack.iscoutb.dev`.
3. **Microsoft Azure App Service (F1 Free Tier).** Aunque el plan es de costo $0, exige la creación de una suscripción respaldada obligatoriamente por una tarjeta de crédito para verificación de identidad, violando la restricción C5 del proyecto.


La infraestructura Azure de `infra/` y `.github/workflows/deploy.yml` queda descartada
como artefacto histórico; el workflow está desactivado y no participa en la publicación.

---

## 2. Estado de la Evidencia e Infraestructura

| Evidencia | Implementación | Estado / Dato a Registrar |
|---|---|---|
| **URL Pública Externa** | Render y Dokploy, HTTPS | `https://inventrack.iscoutb.dev` y `https://inventrack-api.onrender.com` |
| **Infraestructura como Código** | `render.yaml`, `deploy/compose.lab.yaml` y `Dockerfile` | Versionada; Terraform en `infra/` queda como alternativa Azure exploratoria no utilizada |
| **Pipeline CI/CD** | GitHub Actions + autodespliegue Dokploy/Render | GitHub Actions valida la suite; cada plataforma publica desde `main` según su configuración |
| **Health Check** | `GET /health` | Configurado en Render y Dokploy; verificado externamente en ambos destinos |
| **Logs Estructurados** | JSON por línea en `stdout` | Evento `http_request`, sin credenciales ni cuerpos sensibles |
| **Métrica Consultable** | `GET /metrics` | Formato Prometheus; contadores por método y ruta HTTP |
| **Protección de Secretos** | `.env` ignorado y secretos de GitHub | No hay credenciales de ambiente en la rama pública |
| **Run Exitoso** | Dokploy/Render + GitHub Actions | `GET /health` responde 200 en ambos destinos; la suite se ejecuta en GitHub |

---

## 3. Observabilidad y Prueba Externa

Desde una red externa (doméstica o móvil), ejecutar:

```powershell
# Dokploy institucional
curl.exe --fail https://inventrack.iscoutb.dev/health
curl.exe --fail https://inventrack.iscoutb.dev/metrics

# Render
curl.exe --fail https://inventrack-api.onrender.com/health
curl.exe --fail https://inventrack-api.onrender.com/metrics
```

En ambos destinos, `/health` debe responder:

```json
{"status":"ok","service":"InvenTrack"}
```

En ambos destinos, `/metrics` contiene, como mínimo, las series
`inventrack_http_requests_total` y
`inventrack_http_request_duration_seconds_total`.

---

## 4. Contraste: Arranque en Frío (Cold Start) vs. Escenario de Calidad (p95)

* **El Requisito (ESC-04):** El 95% de las peticiones concurrentes ($p95$) deben resolverse en $400\text{ ms}$ o menos.
* **Render:** El plan gratuito puede entrar en suspensión (*spin-down*) tras inactividad.
* **Dokploy:** El servidor institucional mantiene el servicio gestionado por el panel,
	sujeto a la cuota compartida del equipo.
* **Comportamiento en caliente:** En ambos destinos, las transacciones procesadas en
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
* **Render (Free Tier):** $0.00 USD/mes.
* **Dokploy institucional:** $0.00 USD/mes para el equipo; cuota de 512 MB y 0.5 CPU por contenedor.
* **GitHub Actions:** $0.00 USD/mes (Repositorio público).
* **Total Monetario:** **$0.00 USD/mes**.

### Punto de Quiebre (*Breaking Point*)
El modelo gratuito se romperá bajo cualquiera de las siguientes condiciones:
1. **Agotamiento de Memoria (OOM):** El catálogo e historial *in-memory* no deben superar la memoria disponible en el destino usado: 512 MB en Dokploy o el límite del plan gratuito de Render.
2. **Cuota de CPU o compilación:** En Dokploy el equipo no debe superar 0.5 CPU por contenedor ni la memoria compartida durante el build.
3. **Persistencia:** Si la pérdida de datos en memoria deja de ser aceptable, se requiere PostgreSQL u otra persistencia y un nuevo ADR.

---

## 6. Procedimiento de Reversión (Rollback)

### Dokploy institucional

1. Ejecutar `git revert <commit-con-fallo>` en `main`.
2. Esperar la validación de GitHub Actions.
3. Dokploy reconstruirá el servicio `sistema` desde `./deploy/compose.lab.yaml`.
4. Confirmar `https://inventrack.iscoutb.dev/health` y revisar los logs del despliegue.

### Render

1. Abrir el dashboard de Render y seleccionar `inventrack-api`.
2. En **Events/Deploys**, seleccionar el despliegue anterior exitoso y usar **Rollback**.
3. Como alternativa versionada, ejecutar `git revert <commit-con-fallo>` en `main`;
	Render reconstruirá desde `render.yaml` mediante el autodespliegue.
4. Confirmar `https://inventrack-api.onrender.com/health` y revisar sus logs.

---

## 7. Trazabilidad Arquitectónica

La decisión institucional queda formalmente ratificada en [`docs/adr/0006-desplegar-en-dokploy-institucional.md`](./adr/0006-desplegar-en-dokploy-institucional.md), que complementa el ADR-0005 sin reescribirlo.