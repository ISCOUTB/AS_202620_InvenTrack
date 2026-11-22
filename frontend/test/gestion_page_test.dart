import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventrack/main.dart';
import 'package:inventrack/screens/gestion_page.dart';
import 'package:inventrack/services/api_service.dart';

void main() {
  testWidgets('Gestión conecta proveedores, historial, cierre y usuarios',
      (tester) async {
    final proveedores = <Map<String, dynamic>>[];
    final cortes = <Map<String, String>>[];
    final usuarios = <Map<String, dynamic>>[];
    final httpClient = MockClient((request) async {
      Object? cuerpo;
      switch ((request.method, request.url.path)) {
        case ('GET', '/health'):
          cuerpo = {'status': 'ok', 'service': 'InvenTrack'};
        case ('GET', '/sesion'):
          cuerpo = {'rol': 'admin'};
        case ('GET', '/productos'):
          cuerpo = [];
        case ('GET', '/proveedores'):
          cuerpo = proveedores;
        case ('POST', '/proveedores'):
          final p = jsonDecode(request.body) as Map<String, dynamic>;
          proveedores.add({'id': 'p', ...p});
          cuerpo = proveedores.last;
        case ('GET', '/inventario/CAFE/movimientos'):
          cuerpo = [
            {
              'tipo': 'salida',
              'cantidad': 2,
              'registrado_en': '2026-11-22',
              'actor_id': 'caja'
            }
          ];
        case ('GET', '/cierres'):
          cuerpo = cortes;
        case ('POST', '/cierres'):
          cortes.add({'id': 'turno', 'fecha': '2026-11-22'});
          cuerpo = cortes.last;
        case ('POST', '/cierres/turno/conciliar'):
          expect(jsonDecode(request.body)['csv'], 'sku,cantidad\nCAFE,9');
          cuerpo = {
            'total_esperado': 10,
            'total_contado': 9,
            'diferencias': [
              {
                'sku': 'CAFE',
                'motivo': 'cantidad',
                'esperado': 10,
                'contado': 9,
                'diferencia': -1
              }
            ]
          };
        case ('GET', '/usuarios'):
          cuerpo = usuarios;
        case ('POST', '/usuarios'):
          usuarios.add(jsonDecode(request.body));
          cuerpo = {'token': 'ejemplo-de-prueba'};
        default:
          return http.Response('{}', 404);
      }
      return http.Response(jsonEncode(cuerpo), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    await tester.pumpWidget(InvenTrackApp(
        apiService:
            ApiService(client: httpClient, baseUrl: 'http://localhost')));
    await tester.pumpAndSettle();

    Future<void> tocar(Finder control) async {
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
    }

    Future<void> ir(String seccion) async {
      await tocar(find.byType(DropdownButton<Seccion>));
      await tocar(find.text(seccion).last);
    }

    await tocar(find.byTooltip('Gestión'));
    await tocar(find.text('Nuevo proveedor'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre'), 'Cooperativa');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contacto'), 'Oficina');
    await tocar(find.text('Guardar'));
    expect(find.text('Cooperativa'), findsOneWidget);
    expect(find.text('Oficina'), findsOneWidget);

    await ir('Historial por producto');
    await tester.enterText(find.byType(TextField), 'CAFE');
    await tester.pump();
    await tocar(find.text('Consultar historial'));
    expect(find.text('salida · 2 unidades'), findsOneWidget);
    expect(find.textContaining('caja'), findsOneWidget);

    await ir('Cierre de turno');
    await tocar(find.text('Tomar corte de existencias'));
    await tester.enterText(find.byType(TextField), 'sku,cantidad\nCAFE,9');
    await tocar(find.text('Comparar conteo'));
    expect(find.textContaining('Diferencia: -1'), findsOneWidget);

    await ir('Usuarios');
    await tocar(find.text('Crear usuario'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Identificador'), 'turno-tarde');
    await tester.pump();
    await tocar(find.text('Guardar'));
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).data,
        'ejemplo-de-prueba');
    await tocar(find.text('Cerrar'));
    expect(find.text('turno-tarde'), findsOneWidget);
  });
}
