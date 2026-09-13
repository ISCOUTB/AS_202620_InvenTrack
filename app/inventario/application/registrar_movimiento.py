import asyncio
from collections import defaultdict
from contextlib import asynccontextmanager
from dataclasses import dataclass

from app.inventario.domain.exceptions import ProductoSinStockError, StockInsuficienteError
from app.inventario.domain.exceptions_producto import ProductoInvalidoError, TiempoDeEsperaLockAgotado
from app.inventario.domain.movimiento import Movimiento
from app.inventario.domain.ports import MovimientoRepository, StockRepository, ValidadorDeProducto
from app.inventario.domain.stock import StockProducto

LOCK_TIMEOUT_SEGUNDOS = 2.0


@dataclass
class MovimientoInventarioResult:
    producto_id: str
    cantidad: int
    tipo: str
    stock_final: int


class RegistrarMovimientoInventario:

    def __init__(
        self,
        repositorio: StockRepository,
        movimientos: MovimientoRepository,
        validador_producto: ValidadorDeProducto,
        lock_timeout_segundos: float = LOCK_TIMEOUT_SEGUNDOS,
    ):
        self._repositorio = repositorio
        self._movimientos = movimientos
        self._validador_producto = validador_producto
        self._lock_timeout_segundos = lock_timeout_segundos
        self._locks: dict[str, asyncio.Lock] = defaultdict(asyncio.Lock)

    async def registrar_entrada(self, producto_id: str, cantidad: int) -> MovimientoInventarioResult:
        self._validar_producto(producto_id)

        async with self._lock_de(producto_id):
            stock = self._repositorio.obtener(producto_id)
            if stock is None:
                stock = StockProducto(producto_id=producto_id, cantidad=0)

            stock.registrar_entrada(cantidad)
            self._repositorio.guardar(stock)
            self._movimientos.registrar(Movimiento(producto_id, "entrada", cantidad))
            stock_final = stock.cantidad

        return MovimientoInventarioResult(
            producto_id=producto_id,
            cantidad=cantidad,
            tipo="entrada",
            stock_final=stock_final,
        )

    async def registrar_salida(self, producto_id: str, cantidad: int) -> MovimientoInventarioResult:
        self._validar_producto(producto_id)

        async with self._lock_de(producto_id):
            stock = self._repositorio.obtener(producto_id)
            if stock is None:
                raise ProductoSinStockError(producto_id)

            if cantidad > stock.cantidad:
                raise StockInsuficienteError(producto_id, cantidad, stock.cantidad)

            stock.registrar_salida(cantidad)
            self._repositorio.guardar(stock)
            self._movimientos.registrar(Movimiento(producto_id, "salida", cantidad))
            stock_final = stock.cantidad

        return MovimientoInventarioResult(
            producto_id=producto_id,
            cantidad=cantidad,
            tipo="salida",
            stock_final=stock_final,
        )

    def _validar_producto(self, producto_id: str) -> None:
        if not self._validador_producto.existe_y_esta_activo(producto_id):
            raise ProductoInvalidoError(producto_id)

    @asynccontextmanager
    async def _lock_de(self, producto_id: str):
        lock = self._locks[producto_id]
        try:
            await asyncio.wait_for(lock.acquire(), timeout=self._lock_timeout_segundos)
        except asyncio.TimeoutError as exc:
            raise TiempoDeEsperaLockAgotado(producto_id, self._lock_timeout_segundos) from exc
        try:
            yield
        finally:
            lock.release()
