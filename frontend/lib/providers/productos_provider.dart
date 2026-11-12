import 'package:flutter/foundation.dart';

import 'package:inventrack/models/producto.dart';
import 'package:inventrack/services/api_exception.dart';
import 'package:inventrack/services/api_service.dart';

/// Provider de productos que mantiene una lista local en memoria,
/// sincronizada con el backend a través de [ApiService].
class ProductosProvider extends ChangeNotifier {
  final ApiService _apiService;

  ProductosProvider([ApiService? apiService])
      : _apiService = apiService ?? ApiService();

  // ---------------------------------------------------------------------------
  // Estado
  // ---------------------------------------------------------------------------

  final List<Producto> _productos = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Lista inmutable de productos registrados.
  List<Producto> get productos => List.unmodifiable(_productos);

  /// `true` mientras una operación asíncrona está en curso.
  bool get isLoading => _isLoading;

  /// Mensaje de error de la última operación fallida, o `null` si no hay error.
  String? get errorMessage => _errorMessage;

  /// Indica si hay algún error activo.
  bool get hasError => _errorMessage != null;

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  /// Crea un producto en el backend y lo agrega a la lista local si tiene éxito.
  ///
  /// Retorna el [Producto] creado o `null` si ocurre un error.
  Future<Producto?> crearProducto(String id, String nombre) async {
    _setLoading(true);
    _clearError();

    try {
      final request = CrearProductoRequest(id: id, nombre: nombre);
      final producto = await _apiService.crearProducto(request);
      _productos.add(producto);
      return producto;
    } on ApiException catch (e) {
      _errorMessage = e.descripcion;
      return null;
    } on Exception catch (e) {
      _errorMessage = 'Error de conexión: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina un producto del backend y actualiza la lista local según la respuesta.
  ///
  /// - Si fue eliminado físicamente → se remueve de la lista.
  /// - Si fue desactivado (borrado lógico) → se actualiza su estado `activo = false`.
  /// - Si no se encuentra (404) → se establece un mensaje de error y retorna `null`.
  Future<EliminarProductoResponse?> eliminarProducto(String productoId) async {
    _setLoading(true);
    _clearError();

    try {
      final resultado = await _apiService.eliminarProducto(productoId);

      if (resultado.eliminadoFisicamente) {
        _productos.removeWhere((p) => p.id == productoId);
      } else if (resultado.desactivado) {
        final index = _productos.indexWhere((p) => p.id == productoId);
        if (index != -1) {
          _productos[index] = Producto(
            id: _productos[index].id,
            nombre: _productos[index].nombre,
            activo: false,
          );
        }
      }
      return resultado;
    } on ApiException catch (e) {
      _errorMessage = e.descripcion;
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
}
