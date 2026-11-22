import csv


def interpretar_csv(fuente):
    cantidades = {}
    lector = csv.reader(fuente, strict=True)
    cabecera = next(lector, None)
    if cabecera and cabecera[0].startswith("\ufeff"):
        cabecera[0] = cabecera[0].removeprefix("\ufeff")
    if cabecera != ["sku", "cantidad"]:
        raise ValueError("Se esperaba la cabecera sku,cantidad")
    for fila in lector:
        if len(fila) != 2:
            raise ValueError(f"Fila {lector.line_num}: se esperaban dos columnas")
        sku, cantidad = fila
        if not sku.strip() or not cantidad.isascii() or not cantidad.isdecimal():
            raise ValueError(f"Fila {lector.line_num}: se requiere SKU y cantidad entera no negativa")
        if sku in cantidades:
            raise ValueError(f"Fila {lector.line_num}: SKU duplicado: {sku}")
        cantidades[sku] = int(cantidad)
    return cantidades


def comparar(saldos, conteo):
    diferencias = []
    for sku in sorted(saldos.keys() | conteo.keys()):
        esperado = saldos.get(sku)
        contado = conteo.get(sku)
        if esperado == contado:
            continue
        diferencia = None
        if contado is None:
            motivo = "sin_conteo"
        elif esperado is None:
            motivo = "fuera_del_corte"
        else:
            motivo = "diferencia_de_unidades"
            diferencia = contado - esperado
        diferencias.append({"sku": sku, "motivo": motivo, "esperado": esperado,
                            "contado": contado, "diferencia": diferencia})
    return {"total_esperado": sum(saldos.values()), "total_contado": sum(conteo.values()),
            "diferencias": diferencias}
