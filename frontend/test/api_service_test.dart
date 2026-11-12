import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:inventrack/models/movimiento.dart';
import 'package:inventrack/models/producto.dart';
import 'package:inventrack/services/api_exception.dart';
import 'package:inventrack/services/api_service.dart';

void main() {
  group('ApiService contrato OpenAPI v1', () {
    test('checkHealth consulta GET /health', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/health');
        return http.Response(
          jsonEncode({'status': 'ok', 'service': 'InvenTrack'}),
          200,
        );
      });

      final api = ApiService(client: client, baseUrl: 'http://localhost:8000');
      final result = await api.checkHealth();

      expect(result['status'], 'ok');
      expect(result['service'], 'InvenTrack');
    });

    test('crearProducto envia POST /productos y parsea ProductoResponse',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/productos');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {'id': 'SKU-01', 'nombre': 'Tornillo M8'});
        return http.Response(
          jsonEncode({'id': 'SKU-01', 'nombre': 'Tornillo M8', 'activo': true}),
          201,
        );
      });

      final api = ApiService(client: client, baseUrl: 'http://localhost:8000');
      final producto = await api.crearProducto(
        const CrearProductoRequest(id: 'SKU-01', nombre: 'Tornillo M8'),
      );

      expect(producto.id, 'SKU-01');
      expect(producto.nombre, 'Tornillo M8');
      expect(producto.activo, isTrue);
    });

    test('eliminarProducto maneja desactivacion logica ESC-02', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/productos/SKU-01');
        return http.Response(
          jsonEncode({
            'eliminado_fisicamente': false,
            'desactivado': true,
            'mensaje': 'Producto desactivado',
          }),
          200,
        );
      });

      final api = ApiService(client: client, baseUrl: 'http://localhost:8000');
      final res = await api.eliminarProducto('SKU-01');

      expect(res.eliminadoFisicamente, isFalse);
      expect(res.desactivado, isTrue);
    });

    test('registrarEntrada envia headers de trazabilidad e idempotencia',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/inventario/SKU-01/entradas');
        expect(request.headers['X-Correlation-ID'], 'corr-123');
        expect(request.headers['X-Idempotency-Key'], 'idem-123');
        expect(jsonDecode(request.body), {'cantidad': 15});
        return http.Response(
          jsonEncode({
            'producto_id': 'SKU-01',
            'cantidad': 15,
            'tipo': 'entrada',
            'stock_final': 15,
          }),
          200,
        );
      });

      final api = ApiService(client: client, baseUrl: 'http://localhost:8000');
      final mov = await api.registrarEntrada(
        'SKU-01',
        15,
        correlationId: 'corr-123',
        idempotencyKey: 'idem-123',
      );

      expect(mov.productoId, 'SKU-01');
      expect(mov.cantidad, 15);
      expect(mov.tipo, 'entrada');
      expect(mov.stockFinal, 15);
    });

    test('registrarSalida lanza ApiException 409 ante stock insuficiente',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/inventario/SKU-01/salidas');
        return http.Response(
          jsonEncode({'detail': 'Stock insuficiente'}),
          409,
        );
      });

      final api = ApiService(client: client, baseUrl: 'http://localhost:8000');

      expect(
        () => api.registrarSalida('SKU-01', 99),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.message, 'message', 'Stock insuficiente'),
        ),
      );
    });

    test('consultarStock consulta GET /inventario/{producto_id}', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/inventario/SKU-01');
        return http.Response(
          jsonEncode({'producto_id': 'SKU-01', 'cantidad': 10}),
          200,
        );
      });

      final api = ApiService(client: client, baseUrl: 'http://localhost:8000');
      final stock = await api.consultarStock('SKU-01');

      expect(stock.productoId, 'SKU-01');
      expect(stock.cantidad, 10);
    });

    test('MovimientoRequest rechaza cantidad menor o igual a 0', () {
      expect(() => MovimientoRequest(cantidad: 0), throwsArgumentError);
      expect(() => MovimientoRequest(cantidad: -5), throwsArgumentError);
    });
  });
}
