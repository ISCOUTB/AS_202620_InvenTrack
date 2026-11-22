"""Comprueba sin red los enlaces locales de la documentación de entrega."""

import re
import sys
from functools import cache
from pathlib import Path
from urllib.parse import unquote, urlsplit


RAIZ = Path(__file__).resolve().parents[1]
ENLACE = re.compile(r"\[[^\]\n]*\]\(([^)\s]+)\)")


@cache
def lineas(documento):
    visibles = []
    en_bloque = False
    for numero, linea in enumerate(documento.read_text(encoding="utf-8").splitlines(), 1):
        if linea.lstrip().startswith("```"):
            en_bloque = not en_bloque
        elif not en_bloque:
            visibles.append((numero, linea))
    return visibles


@cache
def anclas(documento):
    resultado = set()
    for _, linea in lineas(documento):
        resultado.update(re.findall(r'<a\s+(?:name|id)="([^"]+)"', linea))
        encabezado = re.match(r"^#{1,6}\s+(.+)$", linea)
        if encabezado:
            titulo = encabezado[1].strip().lower()
            base = re.sub(r"[^\w -]", "", titulo).replace(" ", "-")
            ancla = base
            indice = 0
            while ancla in resultado:
                indice += 1
                ancla = f"{base}-{indice}"
            resultado.add(ancla)
    return resultado


def verificar(documento):
    for numero, linea in lineas(documento):
        for enlace in ENLACE.findall(linea):
            url = urlsplit(enlace)
            if url.scheme or url.netloc:
                continue
            destino = documento.parent / unquote(url.path) if url.path else documento
            if not destino.exists() or (
                url.fragment and destino.suffix == ".md"
                and unquote(url.fragment) not in anclas(destino.resolve())
            ):
                yield f"{documento.relative_to(RAIZ)}:{numero} -> {enlace}"


def main():
    documentos = [RAIZ / "README.md", RAIZ / "frontend/README.md", RAIZ / "correcciones.md",
                  *sorted((RAIZ / "docs").rglob("*.md"))]
    errores = [error for documento in documentos for error in verificar(documento)]
    filas = 0
    for numero, linea in lineas(RAIZ / "docs/aspectos.md"):
        if linea.startswith("| ASP-"):
            filas += 1
            celdas = linea.strip("|").split("|")
            if len(celdas) != 8 or any(not ENLACE.search(celda) for celda in celdas[1:]):
                errores.append(f"docs/aspectos.md:{numero} -> eslabón sin enlace")
    if not filas:
        errores.append("docs/aspectos.md -> faltan filas ASP")
    if errores:
        print("\n".join(errores), file=sys.stderr)
        return 1
    print(f"{len(documentos)} documentos con enlaces locales válidos, {filas} aspectos recorridos.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
