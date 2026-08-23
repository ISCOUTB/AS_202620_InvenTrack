# Matriz comparativa de estilos arquitectónicos

Comparación de arquitectura por capas, hexagonal y monolito modular frente a
las restricciones C1-C7 y los escenarios ESC-01 a ESC-05 de
[arc42](arc42/arc42-template-EN.md).

| Criterio | Por capas | Hexagonal | Monolito modular + hexagonal |
|---|---|---|---|
| Despliegue inicial | Sencillo | Sencillo | Sencillo: un único despliegue |
| Separación de infraestructura | Parcial | Fuerte mediante puertos y adaptadores | Fuerte dentro de cada módulo |
| Límites de negocio | Pueden diluirse entre capas | Buenos, pero depende de la organización | Explícitos por módulo y reforzados por puertos |
| Pruebas del dominio | Buenas si se evita acoplamiento | Muy buenas, sin infraestructura real | Muy buenas y escalables por módulo |
| Evolución futura | Puede requerir refactorización amplia | Facilita sustituir adaptadores | Permite extraer módulos si se justifica |
| Complejidad operativa | Baja | Baja | Baja: conserva un solo proceso |
| Riesgo de acoplamiento accidental | Medio | Bajo | Bajo si se respetan los límites |
| Ajuste al equipo y semestre | Bueno | Bueno | **Mejor ajuste** |

## Evaluación frente a InvenTrack

| Criterio | Por capas | Hexagonal | Monolito modular + hexagonal |
|---|---|---|---|
| ESC-01: concurrencia | Medio: la coordinación puede dispersarse | Alto: los casos de uso se aíslan | Alto: inventario queda delimitado y testeable |
| ESC-02: borrado lógico | Medio | Alto: la regla se prueba sin BD | Alto: productos conserva su propia invariante |
| ESC-03: disponibilidad | Depende de toda la aplicación | No resuelve infraestructura | Reduce complejidad, pero un fallo no controlado puede afectar el proceso completo |
| ESC-04: rendimiento | Alto: pocas indirecciones | Medio: añade puertos y adaptadores | Alto: llamadas entre módulos son internas |
| ESC-05: seguridad | Medio: puede mezclarse con endpoints | Alto: autorización separable | Alto: políticas delimitadas por módulo |
| C1: datos personales | Medio | Alto | Alto: usuarios queda delimitado |
| C4: equipo de 3-4 personas | Medio: capas cruzan dominios | Medio | Alto: trabajo organizado por módulo |
| C5: costo | Neutral | Neutral | Neutral; evita el costo operativo de microservicios |

## Decisión comparada

Se elige **Monolito Modular + Hexagonal por módulo**. Combina la simplicidad de
un solo despliegue con límites funcionales explícitos y aislamiento de dominio.
FastAPI será un adaptador de entrada HTTP; la persistencia y la estrategia de
concurrencia se decidirán posteriormente.

Las alternativas se descartan por estas razones:

- **Por capas:** es simple, pero sus límites de negocio son más débiles y puede
  dispersar la lógica de consistencia.
- **Hexagonal como monolito único:** aísla bien la infraestructura, pero no
  organiza por sí sola los cinco dominios funcionales.
- **Monolito modular + hexagonal:** ofrece el mejor equilibrio para un equipo
  pequeño, un semestre y un MVP sin costo operativo distribuido.
