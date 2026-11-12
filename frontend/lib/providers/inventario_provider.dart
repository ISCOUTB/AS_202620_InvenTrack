import 'package:flutter/foundation.dart';

import 'package:inventrack/models/movimiento.dart';
import 'package:inventrack/models/stock.dart';
import 'package:inventrack/services/api_exception.dart';
import 'package:inventrack/services/api_service.dart';

/// Número máximo de movimientos recientes que se conservan para feedback en la UI.
const int _maxMovimientosRecientes = 20;

/// Provider de inventario que gestiona el stock y los movimientos
/// a través de [ApiService].
class InventarioProvider extends ChangeNotifier {
  final ApiService _apiService;
  int _requestSequence = 0;

  InventarioProvider([ApiService? apiService])
      : _apiService = apiService ?? ApiService();

  // ---------------------------------------------------------------------------
  // Estado
  // ---------------------------------------------------------------------------

  /// Caché local de stock: productoId → cantidad.
  final Map<String, int> _stockCache = {};
  Stock? _stockActual;

  bool _isLoading = false;
  String? _errorMessage;

  /// Movimientos recientes para feedback en la UI (últimas operaciones).
  final List<MovimientoResponse> _movimientosRecientes = [];

  /// Caché inmutable de stock consultado.
  Map<String, int> get stockCache => Map.unmodifiable(_stockCache);

  /// Stock consultado o actualizado más recientemente.
  Stock? get stockActual => _stockActual;

  /// `true` mientras una operación asíncrona está en curso.
  bool get isLoading => _isLoading;

  /// Mensaje de error de la última operación fallida, o `null` si no hay error.
  String? get errorMessage => _errorMessage;

  /// Indica si hay algún error activo.
  bool get hasError => _errorMessage != null;

  /// Lista inmutable de los movimientos recientes.
  List<MovimientoResponse> get movimientosRecientes =>
      List.unmodifiable(_movimientosRecientes);

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  /// Consulta el stock actual de un producto y actualiza [stockActual] y [stockCache].
  ///
  /// Posibles errores:
  /// - 404: Producto sin stock registrado.
  Future<Stock?> consultarStock(String productoId) async {
    _setLoading(true);
    _clearError();

    try {
      final stock = await _apiService.consultarStock(productoId);
      _stockActual = stock;
      _stockCache[stock.productoId] = stock.cantidad;
      return stock;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _stockActual = null;
      }
      _errorMessage = e.descripcion;
      return null;
    } on Exception catch (e) {
      _errorMessage = 'Error de conexión: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra una entrada de inventario y actualiza [stockActual] y [stockCache].
  ///
  /// Envía identificadores técnicos opacos en `X-Correlation-ID` y
  /// `X-Idempotency-Key` (sin datos personales, conforme a ADR-0017 y S13).
  Future<MovimientoResponse?> registrarEntrada(
    String productoId,
    int cantidad,
  ) async {
    _setLoading(true);
    _clearError();

    final traceId = _nextTechnicalId('ent');

    try {
      final movimiento = await _apiService.registrarEntrada(
        productoId,
        cantidad,
        correlationId: traceId,
        idempotencyKey: traceId,
      );

      _stockActual = Stock(
        productoId: movimiento.productoId,
        cantidad: movimiento.stockFinal,
      );
      _stockCache[movimiento.productoId] = movimiento.stockFinal;
      _agregarMovimientoReciente(movimiento);
      return movimiento;
    } on ApiException catch (e) {
      _errorMessage = _mensajeErrorEntrada(e);
      return null;
    } on Exception catch (e) {
      _errorMessage = 'Error de conexión: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra una salida de inventario y actualiza [stockActual] y [stockCache].
  ///
  /// Envía identificadores técnicos opacos en `X-Correlation-ID` y
  /// `X-Idempotency-Key` (sin datos personales, conforme a ADR-0017 y S13).
  Future<MovimientoResponse?> registrarSalida(
    String productoId,
    int cantidad,
  ) async {
    _setLoading(true);
    _clearError();

    final traceId = _nextTechnicalId('sal');

    try {
      final movimiento = await _apiService.registrarSalida(
        productoId,
        cantidad,
        correlationId: traceId,
        idempotencyKey: traceId,
      );

      _stockActual = Stock(
        productoId: movimiento.productoId,
        cantidad: movimiento.stockFinal,
      );
      _stockCache[movimiento.productoId] = movimiento.stockFinal;
      _agregarMovimientoReciente(movimiento);
      return movimiento;
    } on ApiException catch (e) {
      _errorMessage = _mensajeErrorSalida(e);
      return null;
    } on Exception catch (e) {
      _errorMessage = 'Error de conexión: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Limpia el mensaje de error actual.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _agregarMovimientoReciente(MovimientoResponse movimiento) {
    _movimientosRecientes.insert(0, movimiento);
    if (_movimientosRecientes.length > _maxMovimientosRecientes) {
      _movimientosRecientes.removeLast();
    }
  }

  String _nextTechnicalId(String prefix) {
    _requestSequence += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_requestSequence';
  }

  /// Genera un mensaje de error específico para operaciones de entrada.
  String _mensajeErrorEntrada(ApiException e) {
    switch (e.statusCode) {
      case 400:
        return 'Cantidad inválida: ${e.message}';
      case 404:
        return 'Producto no encontrado: ${e.message}';
      case 409:
        return 'Conflicto de idempotencia: ${e.message}';
      case 503:
        return 'Servicio no disponible: ${e.message}';
      default:
        return e.descripcion;
    }
  }

  /// Genera un mensaje de error específico para operaciones de salida.
  String _mensajeErrorSalida(ApiException e) {
    switch (e.statusCode) {
      case 400:
        return 'Cantidad inválida: ${e.message}';
      case 404:
        return 'Producto no encontrado o sin stock: ${e.message}';
      case 409:
        return 'Stock insuficiente: ${e.message}';
      case 503:
        return 'Servicio no disponible: ${e.message}';
      default:
        return e.descripcion;
    }
  }
}
