
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/main.dart';
import 'package:inventrack/providers/inventario_provider.dart';
import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/screens/inventario_page.dart';
import 'package:inventrack/screens/productos_page.dart';
import 'package:inventrack/services/api_service.dart';

void main() {
  testWidgets(
    'Flujo basico de productos e inventario con API simulada',
    (WidgetTester tester) async {
      // API simulada para probar sin servidor real.
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/health') {
          return http.Response(
            jsonEncode({
              'status': 'ok',
              'service': 'InvenTrack',
            }),
            200,
          );
        }

        if (request.method == 'GET' &&
            request.url.path == '/productos') {
          return http.Response(
            jsonEncode([]),
            200,
          );
        }

        if (request.method == 'POST' &&
            request.url.path == '/productos') {
          final payload = jsonDecode(request.body)
              as Map<String, dynamic>;

          return http.Response(
            jsonEncode({
              'id': payload['id'],
              'nombre': payload['nombre'],
              'activo': true,
            }),
            201,
          );
        }

        if (request.method == 'POST' &&
            request.url.path ==
                '/inventario/PROD-1/entradas') {
          return http.Response(
            jsonEncode({
              'producto_id': 'PROD-1',
              'cantidad': 12,
              'tipo': 'entrada',
              'stock_final': 12,
            }),
            200,
          );
        }

        return http.Response(
          jsonEncode({'detail': 'Not Found'}),
          404,
        );
      });

      final api = ApiService(
        client: client,
        baseUrl: 'http://localhost:8000',
      );

      await tester.pumpWidget(
        InvenTrackApp(apiService: api),
      );
      await tester.pumpAndSettle();

      // Comprobar pantalla principal.
      expect(
        find.text('InvenTrack'),
        findsOneWidget,
      );

      expect(
        find.text('Resumen de inventario'),
        findsOneWidget,
      );

      // Abrir catálogo.
      await tester.tap(find.text('Productos'));
      await tester.pumpAndSettle();

      // Crear producto.
      await tester.tap(find.text('Nuevo Producto'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'ID del Producto',
        ),
        'PROD-1',
      );

      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Nombre del Producto',
        ),
        'Martillo',
      );

      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      // Verificar que el producto se guardó.
      final productosProvider = tester
          .element(find.byType(ProductosPage))
          .read<ProductosProvider>();

      expect(
        productosProvider.productos.length,
        1,
      );

      expect(
        productosProvider.productos.first.nombre,
        'Martillo',
      );

      // El nuevo catálogo tiene desplazamiento vertical.
      final catalogoScroll = find.descendant(
        of: find.byType(ProductosPage),
        matching: find.byType(Scrollable),
      ).first;

      await tester.scrollUntilVisible(
        find.text('Martillo'),
        200,
        scrollable: catalogoScroll,
      );

      expect(
        find.text('Martillo'),
        findsOneWidget,
      );

      expect(
        find.text('ID: PROD-1'),
        findsOneWidget,
      );

      // Abrir inventario.
      await tester.tap(find.text('Inventario'));
      await tester.pumpAndSettle();

      final inventarioScroll = find.descendant(
        of: find.byType(InventarioPage),
        matching: find.byType(Scrollable),
      ).first;

      // Buscar campo de producto.
      final campoProducto = find.widgetWithText(
        TextFormField,
        'ID del Producto',
      );

      await tester.scrollUntilVisible(
        campoProducto,
        200,
        scrollable: inventarioScroll,
      );

      await tester.enterText(
        campoProducto,
        'PROD-1',
      );

      await tester.pumpAndSettle();

      // Desplazarse hasta la acción de entrada.
      await tester.scrollUntilVisible(
        find.text('Registrar Entrada'),
        200,
        scrollable: inventarioScroll,
      );

      await tester.tap(
        find.text('Registrar Entrada'),
      );

      await tester.pumpAndSettle();

      // Registrar 12 unidades.
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Cantidad',
        ),
        '12',
      );

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Comprobar datos reales del estado local.
      final inventarioProvider = tester
          .element(find.byType(InventarioPage))
          .read<InventarioProvider>();

      expect(
        inventarioProvider.stockActual?.productoId,
        'PROD-1',
      );

      expect(
        inventarioProvider.stockActual?.cantidad,
        12,
      );

      expect(
        inventarioProvider.movimientosRecientes.length,
        1,
      );

      expect(
        inventarioProvider
            .movimientosRecientes.first.stockFinal,
        12,
      );

      // Comprobar la tarjeta de stock.
      await tester.scrollUntilVisible(
        find.text('Stock disponible'),
        200,
        scrollable: inventarioScroll,
      );

      expect(
        find.text('Stock disponible'),
        findsOneWidget,
      );

      expect(
        find.text('Producto: PROD-1'),
        findsOneWidget,
      );

      // Comprobar la tarjeta de movimientos.
      await tester.scrollUntilVisible(
        find.text('Stock final'),
        200,
        scrollable: inventarioScroll,
      );

      expect(
        find.text('Stock final'),
        findsOneWidget,
      );
    },
  );
}
