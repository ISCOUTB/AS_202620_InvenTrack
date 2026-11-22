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
  final String? token;

  ApiService({
    http.Client? client,
    String? baseUrl,
    this.token,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl {
    final uri = Uri.parse(_baseUrl);
    if (token != null &&
        uri.scheme != 'https' &&
        !{'localhost', '127.0.0.1', '::1'}.contains(uri.host)) {
      throw ArgumentError('El acceso individual requiere HTTPS.');
    }
  }

  // ---------------------------------------------------------------------------
  // Headers
  // ---------------------------------------------------------------------------

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
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

  /// GET /productos
  Future<List<Producto>> listarProductos() async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/productos'),
          headers: _jsonHeaders,
        )
        .timeout(ApiConfig.timeout);

    _ensureSuccess(response);

    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((item) => Producto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

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
        .delete(Uri.parse('$_baseUrl/productos/$productoId'),
            headers: _jsonHeaders)
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
          headers: _jsonHeaders,
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

  Future<Object?> _solicitar(String metodo, String ruta,
      [Map<String, dynamic>? datos]) async {
    final mensaje = http.Request(metodo, Uri.parse('$_baseUrl$ruta'));
    mensaje.headers.addAll(_jsonHeaders);
    if (datos != null) mensaje.body = jsonEncode(datos);
    final respuesta = await _client
        .send(mensaje)
        .then(http.Response.fromStream)
        .timeout(ApiConfig.timeout);
    _ensureSuccess(respuesta);
    return respuesta.bodyBytes.isEmpty
        ? null
        : jsonDecode(utf8.decode(respuesta.bodyBytes));
  }

  Future<List<Map<String, dynamic>>> _listar(String ruta) async {
    return (await _solicitar('GET', ruta) as List).cast<Map<String, dynamic>>();
  }

  Future<String> rolActual() async =>
      (await _solicitar('GET', '/sesion') as Map)['rol'] as String;

  Future<List<Map<String, dynamic>>> proveedores() => _listar('/proveedores');

  Future<void> guardarProveedor(String nombre, String contacto,
      {String? id}) async {
    final ruta =
        id == null ? '/proveedores' : '/proveedores/${Uri.encodeComponent(id)}';
    await _solicitar(id == null ? 'POST' : 'PUT', ruta,
        {'nombre': nombre, 'contacto': contacto});
  }

  Future<void> eliminarProveedor(String id) async {
    await _solicitar('DELETE', '/proveedores/${Uri.encodeComponent(id)}');
  }

  Future<List<Map<String, dynamic>>> historial(String sku) =>
      _listar('/inventario/${Uri.encodeComponent(sku)}/movimientos');

  Future<List<Map<String, dynamic>>> cierres() => _listar('/cierres');

  Future<Map<String, dynamic>> abrirCierre() async =>
      await _solicitar('POST', '/cierres') as Map<String, dynamic>;

  Future<Map<String, dynamic>> conciliar(String id, String csv) async =>
      await _solicitar('POST', '/cierres/${Uri.encodeComponent(id)}/conciliar',
          {'csv': csv}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> usuarios() => _listar('/usuarios');

  Future<String> crearUsuario(String id, String rol) async =>
      (await _solicitar('POST', '/usuarios', {'id': id, 'rol': rol})
          as Map)['token'] as String;

  Future<String> rotarUsuario(String id) async =>
      (await _solicitar('POST', '/usuarios/${Uri.encodeComponent(id)}/rotar')
          as Map)['token'] as String;

  Future<void> cambiarRol(String id, String rol) async {
    await _solicitar(
        'PUT', '/usuarios/${Uri.encodeComponent(id)}/rol', {'rol': rol});
  }

  Future<void> revocarUsuario(String id) async {
    await _solicitar('DELETE', '/usuarios/${Uri.encodeComponent(id)}');
  }
}
