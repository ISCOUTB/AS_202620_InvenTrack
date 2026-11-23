# Semana 16 de InvenTrack · borrador de trabajo

[Repositorio](https://github.com/ISCOUTB/AS_202620_InvenTrack) · [Sistema desplegado](https://inventrack.iscoutb.dev).

## Reto propuesto · conciliar el inventario al cierre de turno

Al cerrar la tienda, el encargado cuenta los productos mientras la siguiente caja se prepara para vender. ¿Puede identificar exactamente qué SKU falta o sobra al cierre, aunque las diferencias se compensen en el total y el saldo de la API ya haya cambiado? Los retos anteriores comprobaron la consistencia de los movimientos. Sobre esa base y el respaldo SQLite incorporado después de S15, el nuevo ensayo compara el saldo registrado con una observación independiente en la tienda.

Desde **Gestión → Cierre de turno**, el operador puede tomar un corte y comparar el CSV con los saldos de ese instante. Para trabajar sobre una copia fuera de la aplicación, toma una copia con el [comando de respaldo](../app/shared/infrastructure/respaldo.py) en el corte acordado y registra el conteo de ese mismo instante en un CSV UTF-8 con columnas `sku,cantidad`. Se incluyen los productos activos, incluso sin existencias, y los desactivados que conservan saldo. Una cantidad explícita de cero acredita un SKU contado. Una fila omitida requiere revisión. Si el conteo físico se prolonga mientras cambia la mercancía, el operador debe separar los movimientos del turno siguiente.

| SKU | Saldo de la copia | Conteo del ensayo | Resultado esperado |
|---|---:|---:|---|
| ARROZ | 20 | 18 | Faltan 2 unidades |
| CAFE | 10 | 12 | Sobran 2 unidades |
| TE (desactivado) | 5 | 5 | Coincide |
| SAL | 0 | sin fila | Falta contar el SKU |
| OTRO | fuera del corte | 0 | Revisar identificación |

**Criterio de aceptación.** El control por total da 35 unidades en ambos lados. La conciliación debe señalar los cuatro SKU con incidencias, dejar TE sin marcar y dar cero incidencias con el conteo corregido. ARROZ debe conservar 20 como referencia aunque el saldo operativo baje a 19 después de la copia. El ensayo local verificó los cuatro hallazgos, cero falsos positivos y la integridad del archivo comparado. Es una propuesta para revisión del equipo. [Herramienta](../scripts/conciliar_conteo.py) · [Prueba reproducible](../tests/inventario/test_conciliacion_turno.py).

```sh
python -m pytest -q tests/inventario/test_conciliacion_turno.py
python -m scripts.conciliar_conteo cierre.sqlite3 conteo.csv
```

El segundo comando requiere una copia y un conteo propios. Emite un informe JSON. El código de salida es 0 si todo coincide, 1 si hay diferencias y 2 si la entrada es inválida. La herramienta abre la copia en modo de lectura. El ajuste de existencias, si procede, corresponde al encargado después de revisar el conteo.

## Referencias para preparar el corte

El equipo indicó que Moodle cierra el **22/11/2026 a las 23:55 UTC−5** y que no muestra un desafío específico. El hash publicado observado antes del cierre fue `522af50484dffddd2cb59bee9218ad0d66d40882`, de `2026-11-22T04:23:24-05:00`. Al cierre se podrá identificar la revisión con estos comandos.

```sh
git fetch origin main
git log -1 --format="%H %cI %s" --until="2026-11-22T23:55:00-05:00" origin/main
```

## Alcance desde el segundo corte

S10 se evaluó en `539840be57f8a0b719bb33e19d05031489a25b86`. Hasta la revisión publicada observada cambiaron 170 archivos, con 12 100 inserciones y 242 eliminaciones. Para reproducir el recuento, ejecutar `git diff --shortstat 539840b..522af50`. [Evaluación de S10](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/semana-10-corte2.md) · [Diferencia publicada](https://github.com/ISCOUTB/AS_202620_InvenTrack/compare/539840b...522af50).

| Compromiso o necesidad | Entrega comprobable | Límite |
|---|---|---|
| Catálogo, entradas, salidas e integridad | API y cliente Flutter. El historial impide el borrado físico. [Contrato](api/inventrack-contrato.md) | El equipo comprobó el alta, la entrada y las dos solicitudes de salida desde Flutter contra Dokploy. [Prueba manual](#verificación-pública-y-colaboración). |
| Concurrencia por SKU y p95 ≤ 400 ms | Misma ráfaga en S10, S16 en memoria y S16 durable. [Muestras del candidato](retos/comparacion-s16-final.json) | Una instancia, proceso caliente y ASGI local. |
| Historial, idempotencia e identidad | SQLite conserva movimiento, saldo, evento con actor y resultado del reintento. [Restauración verificada](../tests/test_perfil_durable.py) | El administrador gestiona usuarios desde Flutter o por CLI. El historial por SKU se puede consultar desde otra sesión. Broker y DLQ en memoria. El equipo confirmó la recuperación fuera del host institucional. El ensayo cronometrado en el PC con la copia disponible tardó 1,738 s frente al objetivo de 120 s. |
| Aviso de stock bajo | Flutter muestra «Stock bajo» cuando quedan entre 1 y 10 unidades, ambas inclusive. El equipo observó el aviso en la prueba manual. [Tarjeta de existencias](../frontend/lib/widgets/stock_card.dart) | En SQLite, una salida que cruza de más de 10 a 10 unidades o menos encola un correo. La entrega se probó con un servidor SMTP local. El equipo confirmó también la recepción del aviso desde el despliegue. |
| Gestión de proveedores | Alta, consulta, edición y baja desde Gestión. El directorio persiste en SQLite. [Prueba de integración](../tests/test_gestion_integrada.py). | Verificado localmente. La predicción de demanda quedó fuera del MVP. |

## Concurrencia y recuperación

Como antecedente del nuevo reto se conservan la mejora del escritor SQLite y las mediciones de los cortes anteriores.

Desde la raíz, con Python 3.11 y las dependencias del README, ejecutar `python scripts/comparar_concurrencia.py --actual trabajo --salida resultado-local.json`. El comando extrae el código S10 con Git, crea datos temporales y alterna los perfiles en tres rondas. Cada proceso crea el SKU de arroz, carga 100 unidades y recibe 20 salidas de una unidad, cada una con clave distinta. El p95 es la 19.ª latencia ordenada. Se conservan tiempos individuales, respuestas HTTP y saldos. La herramienta devuelve error si una corrida supera 400 ms. Para repetir la referencia publicada sustituir `trabajo` por `522af50`.

| Ensayo | p95 por corrida (ms) | Resultado |
|---|---|---|
| S10 en memoria, referencia repetida junto al candidato | 15,424 / 13,267 / 13,358 | 3 de 3 dentro del límite |
| S16 en memoria, mismo montaje | 25,795 / 25,283 / 24,471 | 3 de 3 |
| SQLite en el commit publicado, antes del ajuste | 341,296 / 771,660 / 388,914 | 2 de 3 |
| SQLite con conexión escritora reutilizada | 98,660 / 98,089 / 102,243 | 3 de 3 |

Cada corrida terminó con 20 respuestas 200, saldos consecutivos de 99 a 80 y stock final 80. La mediana de los p95 en SQLite bajó 290,254 ms (74,6 %) respecto del perfil durable publicado. El lector puede contrastar también las dos variantes intermedias en el ADR. Las tres rondas describen este equipo y esta carga. [Datos iniciales](retos/comparacion-s10-s16.json) · [Datos finales](retos/comparacion-s16-final.json) · [ADR-0021](adr/0021-serializar-escrituras-sqlite.md).

El ensayo distinto de ESC-01 y ESC-04, del 19 de noviembre, abrió una conexión HTTP real a Uvicorn y autenticó a un administrador de ensayo. En cada una de tres rondas, 50 salidas sobre 40 unidades dieron 40 éxitos y diez conflictos. El p95 de las consultas programadas a 20/s fue 9,169 / 14,095 / 8,000 ms. La prueba de restauración mantiene siete unidades y un solo movimiento al repetir la misma entrada tras recuperar la copia. [Muestras HTTP](retos/escenarios-2026-11-19.json) · [Procedimiento](verificacion-final.md) · [Prueba de recuperación](../tests/test_perfil_durable.py).

En S16 se repitió ese ensayo sobre Uvicorn en loopback, con la conexión escritora del candidato, una base desechable y un usuario autenticado. En cada ronda, 40 ventas se confirmaron, diez obtuvieron 409 y el saldo quedó en cero incluso al repetir la clave. Los tres p95 de lectura fueron **5,644 / 6,057 / 8,336 ms**. Con el ensayo de conciliación se ejecutaron 46 pruebas Python, todas aprobadas. En la verificación previa del cliente pasaron 9 pruebas Flutter. `flutter analyze --no-pub` terminó sin hallazgos. El verificador de CI recorrió los enlaces locales de 49 documentos y los cinco aspectos. [Muestras HTTP del candidato](retos/escenarios-s16-http.json) · [Prueba ejecutada](../tests/inventario/test_escenarios_calidad.py).

**Verificación local de las funciones de Gestión.** Pasaron 48 pruebas de Python y 10 de Flutter. El análisis estático de Flutter terminó sin hallazgos. Además de la prueba de navegación, el cliente HTTP de la aplicación se conectó por loopback a Uvicorn en los perfiles de demostración y SQLite. Se comprobó el directorio, el historial, la conciliación contra un saldo anterior a la venta y, con credencial administrativa, la creación, el cambio de rol, la rotación y la revocación de un usuario. La prueba SMTP recibió un correo al reiniciar con un aviso pendiente. [Pruebas del backend](../tests/test_gestion_integrada.py) · [navegación en Flutter](../frontend/test/gestion_page_test.dart) · [decisión de correo](adr/0022-entregar-alertas-de-stock-desde-sqlite.md).

## Verificación pública y colaboración

El 22/11/2026 a las 04:29 UTC−5 se consultó Dokploy sin credenciales. `GET /health` devolvió 200 y el identificador InvenTrack (1,641 s). `GET /inventario/S16-CONSULTA` devolvió 503 con el mensaje de negocio deshabilitado (0,339 s). `GET /s16-ruta-inexistente` devolvió 404 (0,314 s). La sonda solo acredita ese instante. [Salud](https://inventrack.iscoutb.dev/health) · [Compose](../deploy/compose.lab.yaml).

Tras la activación comunicada por el equipo, se repitieron las lecturas públicas en Dokploy. `GET /health` devolvió **200**. Tanto `GET /productos` como `GET /inventario/S16-CONSULTA` devolvieron **401** con el detalle `Credencial individual requerida`. El cambio de 503 a 401 confirma que las rutas de negocio ya alcanzan la autenticación.

**Prueba manual autenticada.** El equipo reportó que creó un producto desde Flutter contra Dokploy y registró una entrada. La primera salida se aplicó y el saldo mostrado coincidió con el esperado. En la segunda se solicitó una cantidad superior a las existencias disponibles y la operación fue rechazada. Durante la prueba, la tarjeta de existencias mostró «Stock bajo» cuando el producto tenía pocas unidades.

En la comprobación pública posterior a los cambios locales de Gestión, Dokploy respondió 200 a `GET /health` y 404 a `GET /sesion`. En una sonda posterior sin credencial, `/sesion`, `/proveedores`, `/cierres` y `/usuarios` respondieron 401. Una ruta inexistente respondió 404.

**Comprobaciones manuales confirmadas por el equipo.** El equipo probó Gestión desde Flutter con una credencial de ensayo contra Dokploy y confirmó la recepción del correo de stock bajo por SMTP. Para comprobar la recuperación fuera del host, transfirió el respaldo SQLite a su PC, lo restauró como `recuperada.sqlite3` y consultó la API local desde Flutter en `http://127.0.0.1:8001`.

**Repetición cronometrada fuera del host.** Con el respaldo de 86 016 bytes ya disponible en el PC, transcurrieron **1,738 s** frente al objetivo de **120 s** en una ejecución. El cronómetro comenzó al copiar el respaldo a un directorio temporal e incluyó restaurar una base nueva con el comando de respaldo, emitir una credencial de lector de ensayo en esa base, iniciar Uvicorn y consultar un SKU por HTTP. Se detuvo tras recibir 200 y verificar que el SKU y la cantidad coincidían con los del respaldo. La descarga desde Dokploy ya se había completado antes de iniciar el cronómetro. La medición cubre la recuperación local con copia disponible. El tiempo de reponer el servicio público tras perder el host sigue sin medirse.

El historial de la revisión publicada contiene los siguientes aportes por mes de autoría, agrupados por persona, incluidos merges. Se usaron `git shortlog -sne 522af50`, `git log --format="%as %an" 522af50`, correos coincidentes y referencias del curso. Dos commits de José fechados en febrero de 2025 quedan fuera de la tabla. Los ejemplos identifican responsabilidades ejercidas. [Listado oficial](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/EQUIPOS.md) · [Planilla de correspondencias](https://github.com/ISCOUTB/AS_202620_feedback/blob/master/revisiones/2026-2/AS_202620_InvenTrack/planilla.md).

| Integrante y firmas | Ago | Sep | Oct | Nov | Aportes comprobables |
|---|---:|---:|---:|---:|---|
| Félix Taborda · FlexT21, Felix Taborda, negro | 13 | 59 | 21 | 17 | Perfil SQLite y escenarios (`df16ecb`), respaldo y pruebas (`ca2f4e8`). |
| José Vargas · Jose Vargas, Josephva24 | 70 | 60 | 33 | 3 | Simulador de mensajería (`5507934`), decisiones de almacenamiento (`87208d4`). |
| Esteban Peluffo · Esteban Peluffo | 13 | 6 | 5 | 6 | Amenazas y controles (`e12e765`), sincronización de catálogo (`335e524`). |
| Javier Carta · jxviercarta-a11y, atribución provisional en la planilla | 3 | 0 | 0 | 10 | C4 (`dd4ea1c`), interfaz y pruebas ([PR 15](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15)). |

La API pública devolvió ocho PR, siete de Dependabot y el PR 15 del equipo. La consulta de comentarios de revisión en línea devolvió cero. El PR 15 tampoco tenía revisiones ni comentarios de conversación. Una revisión técnica real puede documentarse en el PR de integración antes del cierre. [PR del equipo](https://github.com/ISCOUTB/AS_202620_InvenTrack/pull/15) · [Comentarios de revisión](https://api.github.com/repos/ISCOUTB/AS_202620_InvenTrack/pulls/comments).

## Estado del borrador antes del cierre

El equipo ratificó las decisiones de serializar las escrituras SQLite (ADR-0021), entregar avisos mediante la cola SMTP (ADR-0022) y administrar identidades desde Flutter (ADR-0023). En la revisión publicada `1e3e632` pasaron los checks de CI y el Quality Gate de SonarCloud dio **OK**. [Resultados por revisión](verificacion-final.md#integración-continua-y-quality-gate).

El equipo activó `INVENTRACK_ALLOW_BUSINESS_DATA=true` en Dokploy. Para la comprobación autenticada se requiere una credencial de ensayo contra el volumen de esa instancia. El CLI del [README](../README.md) emite identidades individuales. La credencial de negocio se envía por HTTPS como Bearer y es distinta del secreto operativo de métricas. El jurado puede verificar el SKU desde Flutter o desde la API. Al cierre indicado por el equipo (22/11/2026, 23:55 UTC−5), corresponde identificar el último commit elegible de `main` y vincular los checks y el Quality Gate de esa revisión. La revisión entre pares necesita un enlace a comentarios técnicos reales. La guía de tres páginas, el envío en Moodle y la sustentación quedan para el cierre académico.
