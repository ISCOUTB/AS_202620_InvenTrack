# C4 Nivel 3: Diagrama de Componentes — API Backend InvenTrack

```mermaid
graph TD
    subgraph Backend_FastAPI [Contenedor API FastAPI]
        subgraph Modulo_Productos [Módulo Productos]
            ProdController[Productos Controller HTTP]
            ProdService[Caso de Uso: Crear/Editar Producto]
            ProdRepoPort[Puerto Repositorio Producto]
        end

        subgraph Modulo_Inventario [Módulo Inventario]
            InvController[Inventario Controller HTTP]
            InvService[Caso de Uso: Registrar Movimiento]
            LockManager[Lock Manager por SKU - ADR-0002]
            InvRepoPort[Puerto Repositorio Stock]
        end

        subgraph Modulo_Alertas [Módulo Alertas]
            AlertService[Caso de Uso: Evaluar Umbral]
        end
    end

    Database[(Base de Datos PostgreSQL / SQLite)]

    ProdController --> ProdService
    ProdService --> ProdRepoPort
    InvController --> InvService
    InvService --> LockManager
    LockManager --> InvRepoPort
    
    InvService -- "Notifica evento stock bajo" --> AlertService
    ProdRepoPort --> Database
    InvRepoPort --> Database