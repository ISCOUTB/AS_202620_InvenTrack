# C4 Nivel 3: Diagrama de Componentes — API Backend InvenTrack

**Propósito:** Descomponer la arquitectura interna del contenedor **API Backend (FastAPI)**, mostrando cómo interactúan las capas de los módulos `productos` e `inventario` mediante **Puertos y Adaptadores (Arquitectura Hexagonal)** y el desacoplamiento definido en el **ADR-0003**[cite: 1, 2].

---

## Diagrama de Componentes 

```mermaid
graph TD
    %% Clientes externos
    Client[Cliente HTTP / Frontend / Postman]

    subgraph Backend_FastAPI ["Contenedor: API Backend (Python / FastAPI)"]
        
        %% Módulo Productos
        subgraph Modulo_Productos ["Módulo: app/productos (Contexto Catálogo)"]
            ProdController["ProdController <br> (REST Endpoints)"]
            ProdUseCase["ProdUseCase / Servicio <br> (Casos de Uso Productos)"]
            HistorialAdapter["HistorialMovimientosAdapter <br> (Adaptador de Infraestructura)"]
            ProdRepoPort["ProductosRepositoryPort <br> (Puerto de Dominio/Persistencia)"]
        end

        %% Módulo Inventario
        subgraph Modulo_Inventario ["Módulo: app/inventario (Contexto Stock)"]
            InvController["InvController <br> (REST Endpoints)"]
            InvUseCase["InvUseCase / Servicio <br> (Casos de Uso Inventario)"]
            LockManager["LockManager por SKU <br> (Control de Concurrencia - ADR-0002)"]
            ValidadorAdapter["ValidadorDeProductoAdapter <br> (Adaptador de Infraestructura)"]
            InvRepoPort["InventarioRepositoryPort <br> (Puerto de Dominio/Persistencia)"]
        end

        %% Puertos de Aplicación Inter-módulo (ADR-0003)
        PuertoInvApp["Puerto Aplicación Inventario <br> (ConsultarHistorialMovimientos)"]
        PuertoProdApp["Puerto Aplicación Productos <br> (ConsultarProducto)"]

    end

    %% Base de Datos Externa
    Database[(Base de Datos PostgreSQL / SQLite)]

    %% Relaciones HTTP Clientes
    Client -->|HTTP / REST| ProdController
    Client -->|HTTP / REST| InvController

    %% Flujos Módulo Productos
    ProdController --> ProdUseCase
    ProdUseCase --> ProdRepoPort
    ProdUseCase -->|Petición de verificación ESC-02| HistorialAdapter
    HistorialAdapter -->|Invoca puerto de app| PuertoInvApp
    PuertoInvApp --> InvUseCase

    %% Flujos Módulo Inventario
    InvController --> InvUseCase
    InvUseCase --> LockManager
    LockManager --> InvRepoPort
    InvUseCase -->|Validación de SKU pre-escritura| ValidadorAdapter
    ValidadorAdapter -->|Invoca puerto de app| PuertoProdApp
    PuertoProdApp --> ProdUseCase

    %% Relaciones de Persistencia
    ProdRepoPort --> Database
    InvRepoPort --> Database
```

    ## Descripción Técnica de Componentes

### **Módulo `productos` (`app/productos/`)**
* **`ProdController`:** Expone los endpoints HTTP (`/productos`) para la gestión del catálogo.
* **`ProdUseCase`:** Aplica la lógica de negocio (creación, edición, eliminación lógica) y valida reglas de dominio.
* **`HistorialMovimientosAdapter`:** Implementación en infraestructura que consulta el puerto expuesto por `inventario` para verificar si un producto tiene transacciones registradas antes de ser borrado (`ESC-02`)[cite: 2].

### **Módulo `inventario` (`app/inventario/`)**
* **`InvController`:** Expone los endpoints HTTP (`/inventario/movimientos`, `/inventario/stock`) para operaciones de almacén.
* **`InvUseCase`:** Procesa entradas, salidas y ajustes de stock.
* **`LockManager`:** Implementa exclusión mutua (`asyncio.Lock`) por SKU para prevenir condiciones de carrera ante llamadas simultáneas (`ADR-0002`).
* **`ValidadorDeProductoAdapter`:** Implementación en infraestructura que invoca el puerto expuesto por `productos` para garantizar que no se registren movimientos sobre SKUs inactivos o inexistentes (`ADR-0003`)[cite: 2].