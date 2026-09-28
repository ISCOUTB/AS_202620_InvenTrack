# Infraestructura y Despliegue — InvenTrack

Este directorio y los archivos raíz asociados agrupan los componentes de infraestructura, configuración declarativa de despliegue y los artefactos históricos del sistema InvenTrack.

---

## 1. Estrategia de Despliegue Actual (Render PaaS)

InvenTrack utiliza un enfoque **PaaS (*Platform as a Service*)** basado en contenedores Docker gestionados mediante despliegue continuo desde GitHub. 

* **Plataforma:** Render Web Service (Free Tier).
* **URL Pública de Producción:** `https://inventrack-api.onrender.com`
* **Definición de Infraestructura:**
  * **`Dockerfile` (Raíz):** Define la imagen base de Python, la instalación de dependencias y el comando de arranque con Uvicorn para la API en FastAPI.
  * **`render.yaml` (Raíz):** Archivo de configuración declarativa que automatiza el aprovisionamiento del servicio web, vinculando directamente el repositorio y el archivo Dockerfile con la plataforma de Render.

---

## 2. Contenido del Directorio `infra/` (Artefactos Históricos / Exploratorios)

La carpeta `infra/` contiene los archivos de infraestructura como código (IaC) desarrollados inicialmente para **Microsoft Azure App Service** mediante Terraform.

* **Estado de estos archivos:** **Descartados para producción.**
* **Motivo del descarte:** Durante la fase de aprovisionamiento, se identificó que Azure exige obligatoriamente la asociación de una tarjeta de crédito para validar la suscripción del plan gratuito, violando de forma directa la restricción de presupuesto y negocio **C5 ($0 USD y cero métodos de pago personales)**. 
* **Trazabilidad:** Esta decisión técnica y sus alternativas se encuentran formalmente justificadas en el archivo [`docs/adr/0005-eleccion-plataforma-despliegue.md`](../docs/adr/0005-eleccion-plataforma-despliegue.md). Los archivos de Terraform se conservan en esta carpeta exclusivamente con fines de auditoría histórica y académica.

---

### 3. Guía de Ejecución Local con Docker

Para validar el comportamiento del contenedor de forma idéntica a como corre en el entorno de producción de Render, puedes ejecutar los siguientes comandos desde la raíz del proyecto:

#### Construir la imagen Docker

```powershell
docker build -t inventrack-api .
```

#### Ejecutar el contenedor localmente

PowerShell

```powershell
docker run --rm -p 8000:8000 inventrack-api
```

Una vez ejecutado, la API estará accesible en tu máquina local:

- **Documentación Interactiva (Swagger):** `http://localhost:8000/docs`
- **Verificación de Salud:** `http://localhost:8000/health`
- **Métricas de Observabilidad:** `http://localhost:8000/metrics`

---

## 4. Observabilidad y Monitoreo

El contenedor emite logs estructurados en formato JSON directamente a la salida estándar (`stdout`), los cuales son recolectados por el panel de Render para su supervisión:

- **Formato de Log Estructurado:**

```json
{
  "timestamp": "2026-09-27T23:00:00SZ",
  "level": "INFO",
  "logger": "inventrack.http",
  "message": "{\"event\": \"http_request\", \"method\": \"GET\", \"path\": \"/health\", \"status_code\": 200, \"duration_ms\": 1.245}"
}
```

- **Métrica Consultable (Prometheus):** El endpoint `/metrics` expone contadores de peticiones, duraciones y el cálculo del percentil 95 (`inventrack_http_p95_latency_seconds`) para auditar el cumplimiento del escenario de calidad **ESC-04**.

---

## 5. Referencias y Documentación Asociada

- Guía detallada de costos y punto de ruptura: `docs/despliegue-y-costos.md`
- Registro de Decisión Arquitectónica (ADR-0005): `docs/adr/0005-eleccion-plataforma-despliegue.md`
````
