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

      // Simular las respuestas de la API.
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
          jsonEncode({
            'detail': 'Not Found',
          }),
          404,
        );
      });

      final api = ApiService(
        client: client,
        baseUrl: 'http://localhost:8000',
      );

      // Iniciar la aplicación.
      await tester.pumpWidget(
        InvenTrackApp(apiService: api),
      );

      await tester.pumpAndSettle();

      // Verificar pantalla principal.
      expect(
        find.text('InvenTrack'),
        findsOneWidget,
      );

      expect(
        find.text('Resumen de inventario'),
        findsOneWidget,
      );

      // Abrir la sección Productos.
      await tester.tap(find.text('Productos'));

      await tester.pumpAndSettle();

      // Abrir formulario de producto.
      await tester.tap(
        find.text('Nuevo Producto'),
      );

      await tester.pumpAndSettle();

      // Ingresar información del producto.
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

      // Crear producto.
      await tester.tap(find.text('Crear'));

      await tester.pumpAndSettle();

      // Comprobar que se registró correctamente.
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

      expect(
        productosProvider.productos.first.id,
        'PROD-1',
      );

      // Buscar el producto dentro de la lista.
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

      // Abrir la sección Inventario.
      await tester.tap(
        find.text('Inventario'),
      );

      await tester.pumpAndSettle();

      // Identificar la lista desplazable.
      final inventarioScroll = find.descendant(
        of: find.byType(InventarioPage),
        matching: find.byType(Scrollable),
      ).first;

      // Buscar el campo de ID.
      final campoProducto = find.widgetWithText(
        TextFormField,
        'ID del Producto',
      );

      await tester.scrollUntilVisible(
        campoProducto,
        200,
        scrollable: inventarioScroll,
      );

      // Escribir identificador.
      await tester.enterText(
        campoProducto,
        'PROD-1',
      );

      await tester.pumpAndSettle();

      // Localizar el botón de entrada.
      final botonEntrada = find.text(
        'Registrar Entrada',
      );

      await tester.scrollUntilVisible(
        botonEntrada,
        200,
        scrollable: inventarioScroll,
      );

      // IMPORTANTE:
      // Colocar el botón dentro del área visible
      // para evitar que lo tape la navegación inferior.
      await Scrollable.ensureVisible(
        tester.element(botonEntrada),
        alignment: 0.2,
        duration: const Duration(
          milliseconds: 250,
        ),
      );

      await tester.pumpAndSettle();

      // Registrar entrada.
      await tester.tap(botonEntrada);

      await tester.pumpAndSettle();

      // Ingresar cantidad.
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Cantidad',
        ),
        '12',
      );

      // Confirmar movimiento.
      await tester.tap(
        find.text('Confirmar'),
      );

      await tester.pumpAndSettle();

      // Consultar los datos del inventario.
      final inventarioProvider = tester
          .element(find.byType(InventarioPage))
          .read<InventarioProvider>();

      // Verificar identificador del producto.
      expect(
        inventarioProvider.stockActual?.productoId,
        'PROD-1',
      );

      // Verificar cantidad disponible.
      expect(
        inventarioProvider.stockActual?.cantidad,
        12,
      );

      // Verificar movimiento registrado.
      expect(
        inventarioProvider.movimientosRecientes.length,
        1,
      );

      // Verificar cantidad del movimiento.
      expect(
        inventarioProvider
            .movimientosRecientes.first.cantidad,
        12,
      );

      // Verificar stock después del movimiento.
      expect(
        inventarioProvider
            .movimientosRecientes.first.stockFinal,
        12,
      );

      // Buscar la tarjeta de existencias.
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

      // Buscar la tarjeta de movimientos.
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
