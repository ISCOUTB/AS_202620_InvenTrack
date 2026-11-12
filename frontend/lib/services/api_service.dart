import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:inventrack/config/api_config.dart';
import 'package:inventrack/models/movimiento.dart';
import 'package:inventrack/models/producto.dart';
import 'package:inventrack/models/stock.dart';
import 'package:inventrack/services/api_exception.dart';

class ApiService {
  final http.Client _client;
  final String _baseUrl;

  ApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // ---------------------------------------------------------------------------
  // Headers
  // ---------------------------------------------------------------------------

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  /// GET /health
  Future<Map<String, String>> checkHealth() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/health'))
        .timeout(ApiConfig.timeout);

    _ensureSuccess(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body.map((key, value) => MapEntry(key, value.toString()));
  }

  // ---------------------------------------------------------------------------
  // Productos
  // ---------------------------------------------------------------------------

  /// POST /productos
  Future<Producto> crearProducto(CrearProductoRequest request) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/productos'),
          headers: _jsonHeaders,
          body: jsonEncode(request.toJson()),
        )
        .timeout(ApiConfig.timeout);

    _ensureSuccess(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Producto.fromJson(body);
  }

  /// DELETE /productos/{producto_id}
  Future<EliminarProductoResponse> eliminarProducto(String productoId) async {
    final response = await _client
        .delete(Uri.parse('$_baseUrl/productos/$productoId'))
        .timeout(ApiConfig.timeout);

    _ensureSuccess(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return EliminarProductoResponse.fromJson(body);
  }

  // ---------------------------------------------------------------------------
  // Inventario
  // ---------------------------------------------------------------------------

  /// POST /inventario/{producto_id}/entradas
  Future<MovimientoResponse> registrarEntrada(
    String productoId,
    int cantidad, {
    String? correlationId,
    String? idempotencyKey,
  }) async {
    final request = MovimientoRequest(cantidad: cantidad);
    final headers = _buildMovimientoHeaders(
      correlationId: correlationId,
      idempotencyKey: idempotencyKey,
    );

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/inventario/$productoId/entradas'),
          headers: headers,
          body: jsonEncode(request.toJson()),
        )
        .timeout(ApiConfig.timeout);

    _ensureSuccess(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return MovimientoResponse.fromJson(body);
  }

  /// POST /inventario/{producto_id}/salidas
  Future<MovimientoResponse> registrarSalida(
    String productoId,
    int cantidad, {
    String? correlationId,
    String? idempotencyKey,
  }) async {
    final request = MovimientoRequest(cantidad: cantidad);
    final headers = _buildMovimientoHeaders(
      correlationId: correlationId,
      idempotencyKey: idempotencyKey,
    );

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/inventario/$productoId/salidas'),
          headers: headers,
          body: jsonEncode(request.toJson()),
        )
        .timeout(ApiConfig.timeout);

    _ensureSuccess(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return MovimientoResponse.fromJson(body);
  }

  /// GET /inventario/{producto_id}
  Future<Stock> consultarStock(String productoId) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/inventario/$productoId'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(ApiConfig.timeout);

    _ensureSuccess(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Stock.fromJson(body);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, String> _buildMovimientoHeaders({
    String? correlationId,
    String? idempotencyKey,
  }) {
    final headers = Map<String, String>.from(_jsonHeaders);
    if (correlationId != null) {
      headers['X-Correlation-ID'] = correlationId;
    }
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }
    return headers;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = (body['detail'] ?? body['mensaje'] ?? response.body).toString();
    } catch (_) {
      message = response.body.isNotEmpty
          ? response.body
          : 'Error HTTP ${response.statusCode}';
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
    );
  }

  /// Release the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
