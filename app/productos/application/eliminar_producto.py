from dataclasses import dataclass

from app.productos.domain.exceptions import ProductoNoEncontrado
from app.productos.domain.ports import ProductoRepository, VerificadorDeMovimientos


@dataclass
class ResultadoEliminarProducto:
    eliminado_fisicamente: bool
    desactivado: bool


class EliminarProducto:
    def __init__(
        self,
        repositorio: ProductoRepository,
        verificador_de_movimientos: VerificadorDeMovimientos,
    ):
        self._repositorio = repositorio
        self._verificador = verificador_de_movimientos

    def ejecutar(self, producto_id: str) -> ResultadoEliminarProducto:
        producto = self._repositorio.obtener(producto_id)
        if producto is None:
            raise ProductoNoEncontrado(producto_id)

        if self._verificador.tiene_movimientos_asociados(producto_id):
            producto.desactivar()
            self._repositorio.guardar(producto)
            return ResultadoEliminarProducto(eliminado_fisicamente=False, desactivado=True)

        self._repositorio.eliminar(producto_id)
        return ResultadoEliminarProducto(eliminado_fisicamente=True, desactivado=False)
