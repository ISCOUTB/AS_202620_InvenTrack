from typing import Annotated, Literal

from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel, StringConstraints

from app.shared.infrastructure.sqlite import actor, conexion
from app.usuarios.infrastructure.credenciales import emitir

Usuario_Inexistente = HTTPException(404, "Usuario inexistente")

class Permisos(BaseModel):
    rol: Literal["admin", "operador", "lector"]


class Usuario(Permisos):
    id: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=100,
                                        pattern=r"^[\w.-]+$")]


class Credencial(BaseModel):
    token: str


router = APIRouter()


@router.get("/sesion")
def sesion() -> dict[str, str]:
    identidad = actor.get()
    if identidad is None:
        return {"rol": "demo"}
    rol, = conexion.get().execute("SELECT rol FROM usuarios WHERE id=?", (identidad,)).fetchone()
    return {"rol": rol}


@router.get("/usuarios")
def usuarios() -> list[dict[str, str]]:
    return [{"id": i, "rol": r} for i, r in conexion.get().execute("SELECT id,rol FROM usuarios ORDER BY id")]


@router.post("/usuarios", status_code=201)
def crear_usuario(datos: Usuario, response: Response) -> Credencial:
    db = conexion.get()
    if db.execute("SELECT 1 FROM usuarios WHERE id=?", (datos.id,)).fetchone():
        raise HTTPException(409, "El usuario ya existe")
    response.headers["Cache-Control"] = "no-store"
    return Credencial(token=emitir(db, datos.id, datos.rol))


@router.post("/usuarios/{id}/rotar")
def rotar(id: str, response: Response) -> Credencial:
    db = conexion.get()
    usuario = db.execute("SELECT rol FROM usuarios WHERE id=?", (id,)).fetchone()
    if usuario is None:
        raise Usuario_Inexistente
    if id == actor.get():
        raise HTTPException(409, "Usa otra cuenta administradora para rotar tu credencial")
    response.headers["Cache-Control"] = "no-store"
    return Credencial(token=emitir(db, id, usuario[0]))


@router.put("/usuarios/{id}/rol")
def cambiar_rol(id: str, datos: Permisos) -> dict[str, str]:
    if id == actor.get() and datos.rol != "admin":
        raise HTTPException(409, "Usa otra cuenta administradora para cambiar tu rol")
    if not conexion.get().execute("UPDATE usuarios SET rol=? WHERE id=?", (datos.rol, id)).rowcount:
        raise Usuario_Inexistente
    return {"id": id, "rol": datos.rol}


@router.delete("/usuarios/{id}", status_code=204)
def revocar(id: str) -> Response:
    if id == actor.get():
        raise HTTPException(409, "Usa otra cuenta administradora para revocar tu credencial")
    if not conexion.get().execute("DELETE FROM usuarios WHERE id=?", (id,)).rowcount:
        raise Usuario_Inexistente
    return Response(status_code=204)
