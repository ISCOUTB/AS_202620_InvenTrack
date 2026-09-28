# Guía de Despliegue, Observabilidad y Costos — InvenTrack

**Propósito:** Este documento evalúa las alternativas de despliegue para la API de InvenTrack, justificando la elección operativa según las restricciones de negocio (C5: Costo $0 y sin uso de tarjetas de crédito) y su impacto en los atributos de calidad (ESC-04: p95 $\le$ 400 ms), consolidando la evidencia de observabilidad y operación.

---

## 1. Pieza del Sistema y Alternativas Evaluadas

**Pieza seleccionada:** Contenedor de la API REST (Backend en FastAPI).

Se comparan dos alternativas de despliegue PaaS (*Platform as a Service*):
1. **Alternativa A (Seleccionada): Render Web Service (Free Tier).** Permite el despliegue directo desde GitHub mediante `Dockerfile` / `render.yaml` sin requerir registro de método de pago ni tarjeta de crédito.
2. **Alternativa B (Descartada): Microsoft Azure App Service (F1 Free Tier).** Aunque el plan es de costo $0, exige la creación de una suscripción respaldada obligatoriamente por una tarjeta de crédito para verificación de identidad, violando la restricción C5 del proyecto.

---

## 2. Estado de la Evidencia e Infraestructura

| Evidencia | Implementación | Estado / Dato a Registrar |
|---|---|---|
| **URL Pública Externa** | Render, HTTPS | `https://inventrack-api.onrender.com` |
| **Infraestructura como Código** | `render.yaml` y `Dockerfile` | Versionada; Terraform en `infra/` queda como alternativa Azure exploratoria no utilizada |
| **Pipeline CI/CD** | Render Auto Deploy desde `main` y `test.yml` | Render construye y despliega; GitHub Actions valida la suite de pruebas |
| **Health Check** | `GET /health` | Configurado como probes de salud en Render y validado en CI |
| **Logs Estructurados** | JSON por línea en `stdout` | Evento `http_request`, sin credenciales ni cuerpos sensibles |
| **Métrica Consultable** | `GET /metrics` | Formato Prometheus; contadores por método y ruta HTTP |
| **Protección de Secretos** | `.env` ignorado, `.env.example` y secretos de GitHub | Credenciales de ambiente aisladas de la rama pública |
| **Run Exitoso** | Render Deploy + GitHub Actions | Despliegue verde y suite de pruebas ejecutada con éxito en GitHub |

---

## 3. Observabilidad y Prueba Externa

Desde una red externa (doméstica o móvil), ejecutar:

```powershell
curl.exe --fail [https://inventrack-api.onrender.com/health](https://inventrack-api.onrender.com/health)
curl.exe --fail [https://inventrack-api.onrender.com/metrics](https://inventrack-api.onrender.com/metrics)
```

Resultado esperado del primer comando:

```json
{"status":"ok","service":"InvenTrack"}
```

La segunda respuesta contiene, como mínimo, las series
`inventrack_http_requests_total` y
`inventrack_http_request_duration_seconds_total`.

---

## 4. Contraste: Arranque en Frío (Cold Start) vs. Escenario de Calidad (p95)

* **El Requisito (ESC-04):** El 95% de las peticiones concurrentes ($p95$) deben resolverse en $400\text{ ms}$ o menos.
* **El Comportamiento de Render:** El plan gratuito entra en suspensión (*spin-down*) tras 15 minutos sin recibir tráfico HTTP.
* **El Contraste (Cold Start):** Cuando la API está hibernando, la primera petición sufre un "arranque en frío" que puede demorar **hasta 50,000 ms (50 segundos)**, violando temporalmente la métrica ESC-04.
* **Mitigación / Compensación:** Una vez el contenedor se activa ("caliente"), las transacciones procesadas en memoria se ejecutan en $< 50\text{ ms}$, cumpliendo holgadamente la meta. Se asume esta penalización en la primera petición como un *trade-off* arquitectónico para mantener el costo operativo en $0.00 USD.

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
* **GitHub Actions:** $0.00 USD/mes (Repositorio público).
* **Total Monetario:** **$0.00 USD/mes**.

### Punto de Quiebre (*Breaking Point*)
El modelo gratuito se romperá bajo cualquiera de las siguientes condiciones:
1. **Agotamiento de Memoria (OOM):** El plan gratuito limita la RAM a 512 MB. Si el catálogo e historial *in-memory* superan los 512 MB, el proceso sufrirá un error *Out of Memory* y se reiniciará.
2. **Límite de Tráfico:** Si el volumen escala a 2,000,000 de peticiones/mes (~40 GB de salida y >111 horas de cómputo ininterrumpido), el servicio exigirá la transición al plan **Starter ($7.00 USD/mes)** o la migración a una base de datos relacional externa (ej. PostgreSQL).

---

## 6. Procedimiento de Reversión (Rollback)

En caso de desplegar un fallo en producción, la recuperación no requiere un *git revert* inmediato, sino el uso de la plataforma PaaS:

1. Ingresar al *Dashboard* de Render.
2. Seleccionar el servicio `inventrack-api` y navegar a la pestaña **Events** / **Deploys**.
3. Ubicar el último despliegue previo reportado como exitoso (marcado en verde).
4. Hacer clic en **Rollback to this deploy**.
5. Render enrutará el tráfico HTTP instantáneamente a la imagen previa del contenedor, reduciendo el Tiempo Medio de Recuperación (MTTR) a segundos.

---

## 7. Trazabilidad Arquitectónica

Esta decisión y sus compromisos operativos quedan formalmente ratificados en el archivo [`docs/adr/0005-eleccion-plataforma-despliegue.md`](./adr/0005-eleccion-plataforma-despliegue.md).