import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:inventrack/main.dart';
import 'package:inventrack/services/api_service.dart';

void main() {
  testWidgets('Flujo basico de productos e inventario con API simulada',
      (WidgetTester tester) async {
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/health') {
        return http.Response(
          jsonEncode({'status': 'ok', 'service': 'InvenTrack'}),
          200,
        );
      }
      if (request.method == 'POST' && request.url.path == '/productos') {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
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
          request.url.path == '/inventario/PROD-1/entradas') {
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
      return http.Response(jsonEncode({'detail': 'Not Found'}), 404);
    });

    final api = ApiService(client: client, baseUrl: 'http://localhost:8000');

    await tester.pumpWidget(InvenTrackApp(apiService: api));
    await tester.pumpAndSettle();

    expect(find.text('InvenTrack'), findsOneWidget);
    expect(find.text('Resumen de inventario'), findsOneWidget);

    // Navegar al catálogo y crear producto
    await tester.tap(find.text('Productos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo Producto'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'ID del Producto'),
      'PROD-1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del Producto'),
      'Martillo',
    );
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Martillo'), findsOneWidget);
    expect(find.text('ID: PROD-1'), findsOneWidget);

    // Cambiar a pestana Inventario y registrar entrada
    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'ID del Producto'),
      'PROD-1',
    );
    await tester.tap(find.text('Registrar Entrada'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cantidad'),
      '12',
    );
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Producto: PROD-1'), findsOneWidget);
    expect(find.text('Stock disponible'), findsOneWidget);
    expect(find.text('Stock final'), findsOneWidget);
    expect(find.text('12'), findsNWidgets(2));
  });
}
