class MovimientoRequest {
  final int cantidad;

  MovimientoRequest({required this.cantidad}) {
    if (cantidad <= 0) {
      throw ArgumentError('La cantidad debe ser mayor que 0');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'cantidad': cantidad,
    };
  }
}

class MovimientoResponse {
  final String productoId;
  final int cantidad;
  final String tipo;
  final int stockFinal;

  const MovimientoResponse({
    required this.productoId,
    required this.cantidad,
    required this.tipo,
    required this.stockFinal,
  });

  factory MovimientoResponse.fromJson(Map<String, dynamic> json) {
    return MovimientoResponse(
      productoId: json['producto_id'] as String,
      cantidad: json['cantidad'] as int,
      tipo: json['tipo'] as String,
      stockFinal: json['stock_final'] as int,
    );
  }

  @override
  String toString() =>
      'MovimientoResponse(productoId: $productoId, cantidad: $cantidad, '
      'tipo: $tipo, stockFinal: $stockFinal)';
}
