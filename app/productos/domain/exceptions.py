class ProductoNoEncontrado(Exception):
    def __init__(self, producto_id: str):
        super().__init__(f"Producto no encontrado: {producto_id}")
        self.producto_id = producto_id


class ProductoYaExiste(Exception):
    def __init__(self, producto_id: str):
        super().__init__(f"Producto ya existe: {producto_id}")
        self.producto_id = producto_id
