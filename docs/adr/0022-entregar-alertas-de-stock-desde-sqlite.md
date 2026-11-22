# ADR-0022: Entregar alertas de stock desde una cola SQLite

- **Estado:** Propuesto
- **Fecha:** 2026-11-22
- **Decisores:** Equipo InvenTrack
- **Complementa:** [ADR-0020](0020-persistir-inventario-y-auditoria-en-sqlite.md) y [ADR-0021](0021-serializar-escrituras-sqlite.md)

## Contexto y alternativas

Una venta puede llevar el saldo a diez unidades o menos mientras el encargado está fuera de la aplicación. La tarjeta de Flutter muestra las existencias al consultar el producto. El aviso por correo requiere llegar al encargado incluso después de cerrar el cliente. Enviar el correo durante la venta haría depender el tiempo de respuesta de SMTP. El simulador de mensajería en memoria pierde los avisos pendientes al reiniciar el servicio.

## Decisión

Una salida confirmada que pasa de más de diez unidades a diez o menos guarda el aviso y el identificador del evento en la misma transacción SQLite que el saldo. El despachador envía el correo después de la confirmación, cuando hay un servidor SMTP configurado. Los fallos aplazan un nuevo intento. Tras reponer el producto por encima del umbral, una nueva caída vuelve a generar un aviso.

## Consecuencias y reversión

El encargado recibe un correo por cruce en condiciones normales. Si el proceso termina después de que SMTP acepte el mensaje y antes de marcarlo como enviado, el reintento puede duplicar la entrega. Los reintentos conservan el mismo `Message-ID`. Retirar la configuración SMTP detiene el envío y conserva la cola en el volumen. La prueba utiliza un servidor local que recibe el mensaje tras reiniciar la API con avisos pendientes.

## Trazabilidad

[Adaptador SMTP](../../app/alertas/infrastructure/correo.py) · [prueba del cruce, el reinicio y la entrega](../../tests/test_gestion_integrada.py) · [alcance S16](../preparacion-s16.md).
