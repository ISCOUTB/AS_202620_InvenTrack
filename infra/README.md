# Prototipo de Terraform para Azure App Service

El equipo conserva esta carpeta como registro de la primera propuesta de despliegue de InvenTrack. La configuración de Azure quedó incompleta. Durante el intento de aprovisionamiento, la suscripción solicitó una tarjeta para verificar la cuenta. La restricción C5 del proyecto exigía un presupuesto de cero dólares y excluía el uso de medios de pago personales. El equipo documentó la elección de Render en el [ADR-0005](../docs/adr/0005-eleccion-plataforma-despliegue.md).

Los archivos Terraform describen los [recursos previstos](main.tf), los [parámetros de entrada](variables.tf), los [valores de salida](outputs.tf) y las [versiones requeridas](versions.tf).

El procedimiento del despliegue institucional en Dokploy está en el [README principal](../README.md#despliegue-en-iscoutbdev).
