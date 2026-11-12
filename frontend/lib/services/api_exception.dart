class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  /// Returns a user-friendly description based on the HTTP status code.
  String get descripcion {
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida: $message';
      case 404:
        return 'Recurso no encontrado: $message';
      case 409:
        return 'Conflicto de stock: $message';
      case 422:
        return 'Datos inválidos: $message';
      case 500:
        return 'Error interno del servidor: $message';
      case 503:
        return 'Servicio no disponible: $message';
      default:
        return 'Error ($statusCode): $message';
    }
  }

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
