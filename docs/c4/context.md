# C4 Nivel 1 — Diagrama de Contexto — InvenTrack

## 1. Propósito del diagrama

El modelo C4 permite representar la arquitectura de un sistema mediante
diferentes niveles de abstracción. Cada nivel responde una pregunta diferente
y evita mezclar información de contexto con detalles de implementación.

Los cuatro niveles principales son:

1. **Nivel 1 — Contexto:** ¿quién utiliza el sistema y con qué sistemas
   externos se relaciona?
2. **Nivel 2 — Contenedores:** ¿qué partes principales componen el sistema?
3. **Nivel 3 — Componentes:** ¿qué componentes existen dentro de cada
   contenedor?
4. **Nivel 4 — Código:** ¿cómo se implementan concretamente los componentes?

Este documento corresponde al:

> **C4 Nivel 1 — Diagrama de Contexto de InvenTrack**

El objetivo de este nivel es mostrar el sistema desde una perspectiva
externa, identificando claramente:

- Los actores humanos.
- Los roles específicos de cada actor.
- Las responsabilidades principales de cada actor.
- El sistema que está siendo desarrollado.
- Los sistemas externos relacionados.
- Las relaciones entre los elementos.
- El propósito de cada comunicación.
- Los protocolos o medios de comunicación.
- El límite entre InvenTrack y los elementos externos.

En este nivel, **InvenTrack se considera una caja negra**. No se muestran
todavía sus módulos internos, clases, base de datos, endpoints ni capas
arquitectónicas, ya que estos elementos pertenecen a niveles posteriores
del modelo C4.

---

# 2. Diagrama de contexto

El siguiente diagrama utiliza la notación C4 directamente mediante:

- `Person` para representar personas.
- `System` para representar el sistema principal.
- `System_Ext` para representar sistemas externos.
- `Rel` para representar relaciones entre los elementos.

```mermaid
C4Context

title Diagrama de Contexto — InvenTrack

' ============================================================
' PERSONAS / ACTORES HUMANOS
' ============================================================

Person(
    dueno,
    "Dueño de la PYME",
    "Administrador del sistema. Gestiona usuarios, productos, proveedores e inventario; consulta reportes, historial y recibe alertas."
)

Person(
    vendedor,
    "Vendedor",
    "Operador de Ventas. Consulta el stock y registra salidas de inventario generadas por las ventas."
)

Person(
    bodeguero,
    "Empleado de bodega",
    "Operador de Inventario. Registra entradas de mercancía, ajustes y consulta las existencias."
)

' ============================================================
' SISTEMA PRINCIPAL
' ============================================================

System(
    inventrack,
    "InvenTrack",
    "Sistema de gestión de inventarios para PYMEs. Centraliza productos, proveedores, movimientos, usuarios, trazabilidad y alertas de stock bajo."
)

' ============================================================
' SISTEMA EXTERNO
' ============================================================

System_Ext(
    correo,
    "Servicio de correo electrónico",
    "Servicio externo utilizado para entregar las alertas de stock bajo a los usuarios configurados."
)

' ============================================================
' RELACIONES DE LOS ACTORES CON INVENTRACK
' ============================================================

Rel(
    dueno,
    inventrack,
    "Administra y consulta información del negocio",
    "HTTPS"
)

Rel(
    vendedor,
    inventrack,
    "Consulta stock y registra salidas por ventas",
    "HTTPS"
)

Rel(
    bodeguero,
    inventrack,
    "Registra entradas, ajustes y consulta existencias",
    "HTTPS"
)

' ============================================================
' RELACIÓN ENTRE INVENTRACK Y SISTEMA EXTERNO
' ============================================================

Rel(
    inventrack,
    correo,
    "Solicita el envío de alertas de stock bajo",
    "SMTP / HTTPS"
)

' ============================================================
' ENTREGA DE ALERTAS A LOS USUARIOS
' ============================================================

Rel(
    correo,
    dueno,
    "Entrega alertas configuradas",
    "Correo electrónico"
)

Rel(
    correo,
    vendedor,
    "Entrega alertas configuradas",
    "Correo electrónico"
)

Rel(
    correo,
    bodeguero,
    "Entrega alertas configuradas",
    "Correo electrónico"
)

' ============================================================
' ESTILOS
' ============================================================

' ------------------------------------------------------------
' PERSONAS
' Azul medio
' ------------------------------------------------------------

UpdateElementStyle(
    dueno,
    $bgColor="#1168BD",
    $fontColor="#FFFFFF",
    $borderColor="#0B4884",
    $shadowing="false"
)

UpdateElementStyle(
    vendedor,
    $bgColor="#1168BD",
    $fontColor="#FFFFFF",
    $borderColor="#0B4884",
    $shadowing="false"
)

UpdateElementStyle(
    bodeguero,
    $bgColor="#1168BD",
    $fontColor="#FFFFFF",
    $borderColor="#0B4884",
    $shadowing="false"
)

' ------------------------------------------------------------
' SISTEMA PRINCIPAL
' Azul oscuro
' ------------------------------------------------------------

UpdateElementStyle(
    inventrack,
    $bgColor="#08427B",
    $fontColor="#FFFFFF",
    $borderColor="#052E56",
    $shadowing="false"
)

' ------------------------------------------------------------
' SISTEMA EXTERNO
' Gris
' ------------------------------------------------------------

UpdateElementStyle(
    correo,
    $bgColor="#999999",
    $fontColor="#FFFFFF",
    $borderColor="#6B6B6B",
    $shadowing="false"
)

' ============================================================
' ESTILOS DE RELACIONES
' ============================================================

UpdateRelStyle(
    dueno,
    inventrack,
    $textColor="#333333",
    $lineColor="#1168BD"
)

UpdateRelStyle(
    vendedor,
    inventrack,
    $textColor="#333333",
    $lineColor="#1168BD"
)

UpdateRelStyle(
    bodeguero,
    inventrack,
    $textColor="#333333",
    $lineColor="#1168BD"
)

UpdateRelStyle(
    inventrack,
    correo,
    $textColor="#333333",
    $lineColor="#666666"
)

UpdateRelStyle(
    correo,
    dueno,
    $textColor="#333333",
    $lineColor="#666666"
)

UpdateRelStyle(
    correo,
    vendedor,
    $textColor="#333333",
    $lineColor="#666666"
)

UpdateRelStyle(
    correo,
    bodeguero,
    $textColor="#333333",
    $lineColor="#666666"
)

' ============================================================
' CONFIGURACIÓN DE DISTRIBUCIÓN
' ============================================================

UpdateLayoutConfig(
    $c4ShapeInRow="3",
    $c4BoundaryInRow="1"
)