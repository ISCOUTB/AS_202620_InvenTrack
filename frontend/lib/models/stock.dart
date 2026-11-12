class Stock {
  final String productoId;
  final int cantidad;

  const Stock({
    required this.productoId,
    required this.cantidad,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      productoId: json['producto_id'] as String,
      cantidad: json['cantidad'] as int,
    );
  }

  @override
  String toString() => 'Stock(productoId: $productoId, cantidad: $cantidad)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stock &&
          runtimeType == other.runtimeType &&
          productoId == other.productoId &&
          cantidad == other.cantidad;

  @override
  int get hashCode => productoId.hashCode ^ cantidad.hashCode;
}
