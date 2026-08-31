from dataclasses import dataclass


@dataclass
class StockProducto:
    producto_id: str
    cantidad: int = 0

    def registrar_entrada(self, cantidad: int) -> None:
        if cantidad <= 0:
            raise ValueError("La cantidad de entrada debe ser positiva.")
        self.cantidad += cantidad

    def registrar_salida(self, cantidad: int) -> None:
        if cantidad <= 0:
            raise ValueError("La cantidad de salida debe ser positiva.")
        if cantidad > self.cantidad:
            raise ValueError("La cantidad de salida excede el stock disponible.")
        self.cantidad -= cantidad
