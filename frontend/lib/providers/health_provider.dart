import 'package:flutter/foundation.dart';

import 'package:inventrack/services/api_exception.dart';
import 'package:inventrack/services/api_service.dart';

/// Provider para verificar el estado de salud del backend de InvenTrack.
///
/// Llama al endpoint GET /health y expone el resultado para que la UI
/// pueda mostrar indicadores de conectividad.
class HealthProvider extends ChangeNotifier {
  final ApiService _apiService;

  HealthProvider([ApiService? apiService])
      : _apiService = apiService ?? ApiService();

  // ---------------------------------------------------------------------------
  // Estado
  // ---------------------------------------------------------------------------

  bool _isHealthy = false;
  bool _isChecking = false;
  String? _lastError;

  /// `true` si el último health check fue exitoso.
  bool get isHealthy => _isHealthy;

  /// `true` mientras se está realizando un health check.
  bool get isChecking => _isChecking;

  /// Mensaje de error del último health check fallido, o `null` si fue exitoso.
  String? get lastError => _lastError;

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  /// Realiza un health check al backend (GET /health).
  ///
  /// Actualiza [isHealthy], [isChecking] y [lastError] según el resultado.
  /// Respuesta esperada: `{"status":"ok","service":"InvenTrack"}`
  Future<void> checkHealth() async {
    _isChecking = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _apiService.checkHealth();
      _isHealthy = response['status'] == 'ok';
      if (!_isHealthy) {
        _lastError = 'Estado inesperado del servicio: ${response['status']}';
      }
    } on ApiException catch (e) {
      _isHealthy = false;
      _lastError = e.descripcion;
    } on Exception catch (e) {
      _isHealthy = false;
      _lastError = 'No se pudo conectar al servidor: $e';
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}
