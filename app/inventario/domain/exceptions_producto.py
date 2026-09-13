class ProductoInvalidoError(Exception):
    """El producto referenciado no existe o está desactivado en `productos`."""

    def __init__(self, producto_id: str):
        super().__init__(
            f"El producto {producto_id} no existe o está desactivado; "
            "no se puede registrar un movimiento de inventario para él."
        )
        self.producto_id = producto_id


class TiempoDeEsperaLockAgotado(Exception):

    def __init__(self, producto_id: str, timeout_segundos: float):
        super().__init__(
            f"Tiempo de espera agotado ({timeout_segundos}s) esperando el "
            f"lock de inventario para el producto {producto_id}."
        )
        self.producto_id = producto_id
