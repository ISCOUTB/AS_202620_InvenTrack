# ADR-0001: Monolito Modular con Hexagonal por módulo

- **Estado:** Aceptado
- **Fecha:** 2026-08-30.
- **Decisores:** Equipo InvenTrack.

## Contexto

InvenTrack necesita una base arquitectónica antes de implementar su MVP. El proyecto tiene un equipo de 3 a 4 personas, dedicación parcial, restricciones de costo y un aspecto central de consistencia de datos. Los dominios funcionales anticipados son productos, proveedores, inventario, usuarios y alertas.

La arquitectura debe permitir empezar por la estructura, mantener el dominio separable de FastAPI y la persistencia, y facilitar pruebas de ESC-01 y ESC-02 sin levantar infraestructura real.

## Alternativas consideradas

1. **Arquitectura por capas:** Rápida de iniciar y familiar, pero puede debilitar los límites entre dominios y dispersar reglas entre servicios y repositorios.
2. **Arquitectura hexagonal como monolito único:** Ofrece excelente aislamiento mediante puertos y adaptadores, pero no define por sí sola la separación entre los cinco módulos funcionales.
3. **Monolito modular con hexagonal por módulo:** Combina límites por dominio, testabilidad y un único proceso y despliegue.
4. **Microservicios:** No se adopta por el costo operativo y la complejidad desproporcionada para un equipo de 3-4 personas y un MVP académico.

La comparación detallada está en [matriz-comparativa-estilos.md](../matriz-comparativa-estilos.md).

## Decisión

Se adopta **Monolito Modular** como estilo general, con **Hexagonal (Puertos y Adaptadores)** dentro de cada módulo. La estructura inicial es:

```text
app/
├── main.py
├── shared/
└── <modulo>/
    ├── domain/
    ├── application/
    └── infrastructure/
```

Los módulos son `productos`, `proveedores`, `inventario`, `usuarios` y
`alertas`. Dentro de cada uno, `infrastructure` depende de `application`, y
`application` depende de `domain`. El dominio no depende de frameworks ni de
infraestructura. Los módulos no deben importar directamente el `domain` o la
`infrastructure` de otro módulo; la comunicación se hará por contratos de
aplicación.

FastAPI será el adaptador HTTP y Uvicorn el servidor de desarrollo. La
composición de la aplicación se realiza en `app/main.py`.

## Consecuencias positivas

- Un solo proceso y despliegue reducen la complejidad operativa y el costo.
- Los límites por módulo permiten paralelizar el trabajo del equipo.
- Las reglas de dominio pueden probarse sin depender de FastAPI o una base de
  datos concreta.
- Los adaptadores pueden sustituirse sin cambiar el dominio.
- Un módulo podría extraerse en el futuro si el crecimiento lo justifica.

## Consecuencias negativas y riesgos

- Hay más estructura inicial que en una arquitectura por capas simple.
- El lenguaje no impone completamente los límites; se requiere disciplina y
  revisión de dependencias.
- Un fallo no controlado puede afectar al proceso completo porque sigue siendo
  un monolito.
- Esta decisión no resuelve aún la concurrencia de ESC-01, la idempotencia, la
  base de datos ni el despliegue; serán ADR posteriores.
- El lenguaje (Python) no impone visual ni físicamente la restricción de importaciones entre módulos a menos que se configure una herramienta de análisis estático.
- *Mitigación:* Se evaluará el uso de linters o reglas estáticas (ej. import-linter o pytest-archon) en el pipeline de CI para bloquear importaciones cruzadas prohibidas.

## Evidencia inicial

- Aplicación FastAPI en `app/main.py`.
- Endpoint técnico `GET /health`.
- Prueba automatizada en `tests/test_health.py`.
- Comando de arranque documentado en el README:
  `python -m uvicorn app.main:app --reload`.
