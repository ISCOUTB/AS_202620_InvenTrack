from dataclasses import dataclass, field
from datetime import datetime, timezone


@dataclass
class Movimiento:

    producto_id: str
    tipo: str  # "entrada" | "salida"
    cantidad: int
    registrado_en: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
