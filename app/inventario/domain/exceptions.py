class StockInsuficienteError(Exception):
    def __init__(self, producto_id: str, cantidad_solicitada: int, stock_actual: int):
        super().__init__(
            f"Stock insuficiente para el producto {producto_id}: "
            f"solicitado={cantidad_solicitada}, disponible={stock_actual}"
        )
        self.producto_id = producto_id
        self.cantidad_solicitada = cantidad_solicitada
        self.stock_actual = stock_actual


class ProductoSinStockError(Exception):
    def __init__(self, producto_id: str):
        super().__init__(f"El producto {producto_id} no tiene un registro de stock inicial.")
        self.producto_id = producto_id
