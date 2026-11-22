from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel, StringConstraints

from app.shared.infrastructure.sqlite import conexion


class DatosProveedor(BaseModel):
    nombre: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=160)]
    contacto: Annotated[str, StringConstraints(strip_whitespace=True, max_length=250)] = ""


class Proveedor(DatosProveedor):
    id: str


def crear_router(durable: bool):
    router = APIRouter(prefix="/proveedores")
    memoria: dict[str, Proveedor] = {}

    @router.get("")
    async def listar() -> list[Proveedor]:
        if durable:
            filas = conexion.get().execute("SELECT id,nombre,contacto FROM proveedores ORDER BY nombre,id")
            return [Proveedor(id=i, nombre=n, contacto=c) for i, n, c in filas]
        return sorted(memoria.values(), key=lambda p: (p.nombre, p.id))

    @router.post("", status_code=201)
    async def crear(datos: DatosProveedor) -> Proveedor:
        proveedor = Proveedor(id=str(uuid4()), **datos.model_dump())
        if durable:
            conexion.get().execute("INSERT INTO proveedores(id,nombre,contacto) VALUES(?,?,?)",
                                   (proveedor.id, proveedor.nombre, proveedor.contacto))
        else:
            memoria[proveedor.id] = proveedor
        return proveedor

    @router.put("/{id}")
    async def actualizar(id: str, datos: DatosProveedor) -> Proveedor:
        proveedor = Proveedor(id=id, **datos.model_dump())
        if durable:
            existe = conexion.get().execute("UPDATE proveedores SET nombre=?,contacto=? WHERE id=?",
                                            (datos.nombre, datos.contacto, id)).rowcount
        else:
            existe = id in memoria
            if existe:
                memoria[id] = proveedor
        if not existe:
            raise HTTPException(404, "Proveedor inexistente")
        return proveedor

    @router.delete("/{id}", status_code=204)
    async def eliminar(id: str) -> Response:
        if durable:
            existe = conexion.get().execute("DELETE FROM proveedores WHERE id=?", (id,)).rowcount
        else:
            existe = memoria.pop(id, None) is not None
        if not existe:
            raise HTTPException(404, "Proveedor inexistente")
        return Response(status_code=204)

    return router
