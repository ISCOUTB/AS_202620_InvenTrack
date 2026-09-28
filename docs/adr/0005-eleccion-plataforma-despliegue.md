# ADR-0005: Pivote y Elección Definitiva de Plataforma de Despliegue (Render PaaS)

**Fecha:** 2026-09-27
**Estado:** Aceptado

## Contexto y Problema
El sistema InvenTrack requiere un entorno de despliegue público, estable y accesible a través de Internet para validar los contratos de la API y permitir la evaluación del proyecto. 

Dentro de los atributos del sistema, existe una **restricción arquitectónica estricta de negocio (C5)**: el costo de infraestructura debe ser exactamente de cero dólares ($0 USD) recurrentes, y no se debe exigir el registro de tarjetas de crédito o métodos de pago personales por parte de los desarrolladores (estudiantes).

### El Intento Fallido con Microsoft Azure
Inicialmente, el equipo diseñó una estrategia de despliegue basada en contenedores hacia **Azure App Service**. Se llegó a codificar la infraestructura como código (Terraform) y se construyó el pipeline de integración y despliegue continuo en GitHub Actions (evidenciado en el archivo `deploy.yml` y los artefactos de la carpeta `infra/`). 

Sin embargo, durante la fase de ejecución, el equipo se encontró con un bloqueo insalvable: aunque Azure ofrece una capa gratuita (Plan F1), la plataforma de Microsoft exige la creación de una suscripción activa respaldada obligatoriamente por una tarjeta de crédito válida para verificación de identidad y cobro de posibles excedentes. Esto violaba directamente la restricción C5 y representaba un riesgo financiero inaceptable para el equipo, obligando a abortar este camino.

### Evaluación de Alternativas
Ante este impedimento, se evaluaron dos caminos adicionales:

1. **Servidores On-Premise (Infraestructura de la Universidad - UTB):** 
   * *Ventajas:* Control total, sin costos directos en dólares.
   * *Desventajas:* Requiere una alta carga operativa (DevOps). Implica gestionar permisos de red, abrir puertos a través del firewall institucional de la universidad, configurar proxies inversos y lidiar con burocracia administrativa que excede el tiempo disponible para el ciclo de desarrollo.
2. **Render Cloud (PaaS):** 
   * *Ventajas:* Ofrece un plan "Free Web Service" nativo. No solicita método de pago para utilizar los recursos gratuitos. Se integra de forma nativa con GitHub para el despliegue automático mediante configuración declarativa (`render.yaml`).
   * *Desventajas:* El servicio entra en hibernación (spin-down) tras 15 minutos sin recibir tráfico.

## Decisión
Se decide **abandonar definitivamente la infraestructura en Microsoft Azure** y adoptar **Render (PaaS)** como la plataforma oficial de despliegue productivo para InvenTrack. El despliegue se gestionará mediante el archivo de configuración `render.yaml` conectado directamente a la rama `main` del repositorio.

## Justificación de la Decisión
1. **Cumplimiento Absoluto de C5:** Render permite desplegar la API y exponerla públicamente sin requerir el ingreso de una tarjeta de crédito en ningún momento del registro o despliegue.
2. **Fricción Operativa Cercana a Cero (NoOps):** A diferencia de Azure (que requería gestionar *Service Principals*, *Tenants* y secretos complejos en GitHub), o de la opción On-Premise en la universidad, Render abstrae toda la complejidad de la infraestructura. Detecta automáticamente los commits y ejecuta el comando de inicio del contenedor (`Dockerfile`) sin pipelines de despliegue adicionales.
3. **Observabilidad Integrada:** La plataforma ofrece un dashboard básico gratuito donde el equipo puede monitorear los logs de los contenedores y el tráfico HTTP en tiempo real, lo que apoya la medición del escenario de calidad ESC-04.

## Estimación de Costo y Punto de Ruptura de la Capa Gratuita
* **Costo mensual por pieza:**
  * *API Backend (Render Web Service - Free Tier):* **$0.00 USD** (otorga hasta 750 horas de ejecución al mes, cubriendo holgadamente las ~730 horas de un mes estándar).
  * *Capa de Persistencia (In-Memory dentro del contenedor):* **$0.00 USD** (sin bases de datos administradas de pago).
* **Punto de Ruptura (Volumen y Límites):** 
  El límite crítico de la capa gratuita es la asignación de **512 MB de RAM** y CPU compartida. Dado que la persistencia de InvenTrack opera temporalmente *in-memory* en esta fase, el punto de ruptura operativo se alcanzará cuando el volumen acumulado de datos (productos, catálogos e historiales de movimientos) sature los 512 MB de memoria RAM del contenedor. Superar este volumen provocará que la plataforma termine el proceso de la aplicación por un error **OOM (Out Of Memory)**. En ese escenario futuro, la arquitectura se verá obligada a extraer la persistencia hacia un motor externo (como PostgreSQL), rompiendo la restricción C5 de costo cero.

## Consecuencias
* **Positivas:** El equipo recupera la capacidad de despliegue sin romper las restricciones de presupuesto ni arriesgar información financiera. La configuración con `render.yaml` garantiza reproducibilidad. La API se encuentra operativa respondiendo en su URL pública.
* **Negativas / Mitigaciones:** 
  * *Cold Starts (Arranques en frío):* Debido a la naturaleza del tier gratuito, las peticiones que "despierten" a la API tras 15 minutos de inactividad experimentarán una latencia elevada (hasta 50 segundos). **Mitigación:** Para las pruebas de estrés o la medición de la métrica $p95 \le 400\text{ ms}$ (ESC-04), el equipo realiza previamente una petición de calentamiento (`/health`) y ejecuta las mediciones únicamente con la instancia activa ("Live").