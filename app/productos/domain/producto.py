from dataclasses import dataclass


@dataclass
class Producto:
    id: str
    nombre: str
    activo: bool = True

    def desactivar(self) -> None:
        self.activo = False
