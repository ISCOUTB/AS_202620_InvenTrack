class Producto {
  final String id;
  final String nombre;
  final bool activo;

  const Producto({
    required this.id,
    required this.nombre,
    required this.activo,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      activo: json['activo'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'activo': activo,
    };
  }

  @override
  String toString() => 'Producto(id: $id, nombre: $nombre, activo: $activo)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Producto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre &&
          activo == other.activo;

  @override
  int get hashCode => id.hashCode ^ nombre.hashCode ^ activo.hashCode;
}

class CrearProductoRequest {
  final String id;
  final String nombre;

  const CrearProductoRequest({
    required this.id,
    required this.nombre,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

class EliminarProductoResponse {
  final bool eliminadoFisicamente;
  final bool desactivado;
  final String mensaje;

  const EliminarProductoResponse({
    required this.eliminadoFisicamente,
    required this.desactivado,
    required this.mensaje,
  });

  factory EliminarProductoResponse.fromJson(Map<String, dynamic> json) {
    return EliminarProductoResponse(
      eliminadoFisicamente: json['eliminado_fisicamente'] as bool,
      desactivado: json['desactivado'] as bool,
      mensaje: json['mensaje'] as String,
    );
  }

  @override
  String toString() =>
      'EliminarProductoResponse(eliminadoFisicamente: $eliminadoFisicamente, '
      'desactivado: $desactivado, mensaje: $mensaje)';
}
