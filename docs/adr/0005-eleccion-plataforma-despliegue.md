# ADR-0005: Pivote y Elección Definitiva de Plataforma de Despliegue (Render PaaS)

**Fecha:** 2026-09-27
**Estado:** Aceptado

## Contexto y Problema
El sistema InvenTrack requiere un entorno de despliegue público, estable y accesible a través de Internet para validar los contratos de la API, permitir la ejecución de pruebas de integración remotas y facilitar la evaluación integral del proyecto. 

Dentro de los atributos del sistema, existe una **restricción arquitectónica estricta de negocio (C5)**: el costo de infraestructura debe ser exactamente de cero dólares ($0 USD) recurrentes, y bajo ninguna circunstancia se debe exigir el registro de tarjetas de crédito, métodos de pago personales o contratos de consumo por parte de los desarrolladores (estudiantes).

### El Intento Fallido y Descarte de Microsoft Azure
Inicialmente, el equipo diseñó una estrategia de despliegue basada en contenedores hacia **Microsoft Azure App Service** (Plan F1 Free Tier). Se llegó a codificar la infraestructura declarativa mediante Terraform y se construyó el pipeline de integración y despliegue continuo en GitHub Actions (evidenciado en el historial de commits y los artefactos de la carpeta `infra/`). 

Sin embargo, durante la fase de ejecución y aprovisionamiento, el equipo se encontró con una barrera institucional insalvable: aunque la capa es conceptualmente gratuita, la política de seguridad y validación de identidad de Azure exige obligatoriamente asociar una tarjeta de crédito válida a la suscripción para autorizar la creación de recursos web. Esta exigencia vulnera de forma directa y frontal la **restricción C5** e introduce un riesgo financiero inaceptable por cobros accidentales de excedentes. Como consecuencia, **se abortó formalmente este camino técnico**. 

> *Nota de arquitectura:* El código de Terraform previamente desarrollado en la carpeta `infra/` se conserva exclusivamente como un artefacto histórico y exploratorio de esta fase descartada, quedando formalmente reemplazado por la estrategia declarativa actual.

### Evaluación de Alternativas de Reemplazo
Ante la inviabilidad de Azure, se evaluaron dos alternativas viables:

1. **Servidores On-Premise (Infraestructura institucional de la UTB):** 
   * *Ventajas:* Control absoluto del hardware y cero costos monetarios directos.
   * *Desventajas:* Alta fricción operativa (DevOps intensivo). Exige gestionar aperturas de puertos en el firewall de la red institucional, configurar proxies inversos y lidiar con políticas de red restrictivas que atentan contra la disponibilidad continua y escapan al tiempo del ciclo de desarrollo.
2. **Render Cloud (PaaS) (Seleccionada):** 
   * *Ventajas:* Ofrece un plan "Free Web Service" nativo que no solicita ningún tipo de información de pago ni tarjeta de crédito durante el registro o despliegue. Se integra de manera fluida y declarativa con GitHub mediante `render.yaml`.
   * *Desventajas:* El servicio entra en estado de suspensión (*spin-down*) tras 15 minutos de inactividad por falta de tráfico HTTP.

## Decisión
Se decide **abandonar definitivamente la infraestructura en Microsoft Azure**, catalogar el código de Terraform en `infra/` como prototipo histórico descartado, y adoptar **Render (PaaS)** como la plataforma oficial de despliegue productivo para la API de InvenTrack, utilizando el archivo de configuración `render.yaml` vinculado a la rama principal (`main`).

## Justificación Rigurosa de la Decisión
1. **Garantía Absoluta del Cumplimiento de C5:** Render permite el aprovisionamiento, despliegue y exposición pública de servicios en contenedores sin requerir validación bancaria ni métodos de pago, eliminando el riesgo de pasarelas de cobro o endeudamiento estudiantil.
2. **Filosofía NoOps y Reducción de Costo Cognitivo:** A diferencia de Azure (que obligaba a configurar arquitecturas complejas de autenticación IAM, *Service Principals* y secretos de infraestructura en GitHub Actions), Render abstrae la gestión del servidor. El motor detecta el `Dockerfile` y compila de forma autónoma, permitiendo que el equipo concentre sus esfuerzos en la lógica de negocio y la calidad del software.
3. **Observabilidad Nativa y Trazabilidad:** Proporciona logs centralizados en tiempo real y métricas esenciales que facilitan la auditoría del comportamiento de la API frente a los requisitos funcionales y no funcionales.

## Estimación de Costo y Punto de Ruptura de la Capa Gratuita
* **Costo Operativo Mensual:**
  * *API Backend (Render Web Service - Free Tier):* **$0.00 USD** (concede hasta 750 horas de cómputo al mes, cubriendo holgadamente el ciclo mensual estándar).
  * *Capa de Persistencia:* **$0.00 USD** (operación transaccional temporal *in-memory*).
* **Punto de Ruptura (*Breaking Point*):** 
  El sistema operativo gratuito impone un límite estricto de **512 MB de RAM** y recursos de CPU compartido. El punto de quiebre técnico se alcanzará en el momento en que el volumen acumulado de registros en memoria (catálogos de productos y transacciones) sature los 512 MB, provocando un reinicio forzoso del contenedor por error de desbordamiento de memoria (**OOM - Out Of Memory**). Superar este umbral exigirá obligatoriamente migrar hacia un motor de base de datos relacional externo y escalar al plan de pago *Starter* ($7.00 USD/mes), rompiendo la restricción C5 y requiriendo un nuevo ADR.

## Consecuencias y Mitigaciones
* **Positivas:** Recuperación inmediata de la capacidad de despliegue continuo (CI/CD), reproducibilidad garantizada mediante configuración como código (`render.yaml`) y preservación intacta del presupuesto del proyecto ($0.00 USD).
* **Negativas / Mitigaciones:** 
  * *Arranques en Frío (Cold Starts):* La inactividad prolongada genera una latencia anómala de hasta 50 segundos en la primera petición tras el despertar del contenedor, lo cual choca temporalmente con el escenario de calidad **ESC-04** ($p95 \le 400\text{ ms}$). 
  * *Mitigación Arquitectónica:* Se establece por protocolo de evaluación que, previo a cualquier medición de rendimiento o auditoría del atributo ESC-04, se ejecute una petición preliminar de calentamiento (`GET /health`) para asegurar que la instancia se encuentre activa (*Live*), aislando así el estado de régimen permanente (*warm state*) del comportamiento transitorio de hibernación.