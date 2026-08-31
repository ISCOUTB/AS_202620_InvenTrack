# C4 Nivel 2 — Diagrama de Contenedores — InvenTrack

## Qué muestra este nivel y por qué

El Nivel 2 abre la caja que en el Nivel 1 (`docs/c4/context.md`) era
"InvenTrack" y muestra los **contenedores**: unidades que se pueden
ejecutar o desplegar por separado (una aplicación, una API, una base de
datos). "Contenedor" aquí es un término de C4, **no** de Docker — no
implica necesariamente contenedorización.

Los tres actores (Dueño, Vendedor, Empleado de bodega) y sus roles son
los mismos del Nivel 1; no se repiten explicaciones aquí, solo el
diagrama y lo que cambia al entrar al sistema.

```mermaid
flowchart TB
    Dueno(("👤 Dueño de la PYME
    Rol: Administrador"))
    Vendedor(("👤 Vendedor
    Rol: Operador de Ventas"))
    Empleado(("👤 Empleado de bodega
    Rol: Operador de Inventario"))

    subgraph InvenTrack["InvenTrack — Monolito Modular (ADR-0001)"]
        Web[["🖥️ Interfaz web
        Por definir"]]
        Api[["⚙️ API Backend
        FastAPI + Uvicorn"]]
        Db[("🗄️ Base de datos
        Por definir")]
    end

    Notif(["✉️ Notificaciones
    Vía correo"])

    Dueno -- HTTPS --> Web
    Vendedor -- HTTPS --> Web
    Empleado -- HTTPS --> Web
    Web -- "HTTPS/REST" --> Api
    Api -- "SQL/ORM" --> Db
    Api -- SMTP --> Notif

    classDef person fill:#1168bd,stroke:#0b4884,color:#ffffff,font-weight:bold
    classDef container fill:#1a6fc4,stroke:#0e4d8a,color:#ffffff,font-weight:bold
    classDef db fill:#2e86c1,stroke:#1b4f72,color:#ffffff,font-weight:bold
    classDef external fill:#999999,stroke:#6b6b6b,color:#ffffff,font-weight:bold

    class Dueno,Vendedor,Empleado person
    class Web,Api container
    class Db db
    class Notif external
```

## Leyenda

| Símbolo | Forma | Color (hex) | Significado |
|---|---|---|---|
| 👤 | Círculo doble | Azul medio `#1168bd` | **Persona** — igual que en el Nivel 1 |
| 🖥️ / ⚙️ | Rectángulo de doble borde | Azul contenedor `#1a6fc4` | **Contenedor de aplicación** — algo que se ejecuta (web o API) |
| 🗄️ | Cilindro (base de datos) | Azul base de datos `#2e86c1` | **Contenedor de datos** — forma estándar de C4 para persistencia |
| ✉️ | Óvalo (estadio) | Gris `#999999` | **Externo** — igual que en el Nivel 1 |

## Por qué solo 3 contenedores (y no 5, uno por módulo)

El [ADR-0001](../adr/0001-usar-monolito-modular-con-hexagonal-por-modulo.md)
decide explícitamente un **Monolito Modular**: un único proceso
desplegado, no servicios separados. Por eso los cinco módulos
funcionales (`productos`, `proveedores`, `inventario`, `usuarios`,
`alertas`) **no aparecen como contenedores independientes** — todos
viven *dentro* del mismo contenedor "API Backend". Esa separación
por módulo se documentará en el **Nivel 3 (Componentes)**, que abre
la caja de "API Backend" y sí muestra cada módulo como una unidad
propia.

Si en el futuro el equipo decide extraer algún módulo a su propio
servicio (por ejemplo, si `inventario` creciera mucho en tráfico),
ahí sí aparecería como un cuarto contenedor — pero hoy, con el ADR-0001
vigente, no es el caso.

## Correspondencia con la estructura de código

| Contenedor en el diagrama | Corresponde a | Estado |
|---|---|---|
| API Backend | Toda la carpeta [`app/`](../../app/) — un único proceso FastAPI que ensambla los cinco módulos en `app/main.py` | Esqueleto ejecutable (endpoint `/health` únicamente, sin lógica de negocio aún) |
| Interfaz web | Aún no existe en el repositorio | Pendiente — depende de la decisión de stack de frontend |
| Base de datos | Aún no existe en el repositorio | Pendiente — depende de la decisión de stack de persistencia |

**Los módulos (`app/productos/`, `app/proveedores/`, `app/inventario/`,
`app/usuarios/`, `app/alertas/`), cada uno con su `domain/`,
`application/` e `infrastructure/`, son estructura *interna* del
contenedor "API Backend"** — no aparecen como cajas propias en este
diagrama de Nivel 2 porque, para C4, siguen siendo el mismo contenedor
desplegable. Su desglose correcto es el Nivel 3 (Componentes).

## Qué falta y qué sigue

- **Nivel 3 (Componentes):** abrir la caja "API Backend" y mostrar los
  cinco módulos como componentes, cada uno con sus tres capas
  (`domain`, `application`, `infrastructure`) — esto es lo que
  demuestra visualmente que la estructura de carpetas ya creada
  corresponde a la arquitectura hexagonal decidida en el ADR-0001.
- **Interfaz web y Base de datos:** ambas están como "Por definir"
  porque el stack de frontend y de persistencia todavía no se ha
  decidido (ver Technical Context en el arc42). Cuando se decida, este
  archivo se actualiza y probablemente se registre como un nuevo ADR.