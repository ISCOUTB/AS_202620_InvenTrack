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
import 'package:inventrack/ui/inventrack_style.dart';

double contraste(Color texto, Color fondo) {
  final a = texto.computeLuminance();
  final b = fondo.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

void main() {
  testWidgets('Cada destino selecciona su vista y salir depende de la sesión', (tester) async {
    final servicio = ApiService(client: MockClient((request) async {
      return http.Response(request.url.path == '/productos' ? '[]' : '{"status":"ok"}', 200);
    }));
    addTearDown(servicio.dispose);
    await tester.pumpWidget(InvenTrackApp(apiService: servicio));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cerrar sesión'), findsNothing);
    const destinos = ['Inicio', 'Productos', 'Inventario'];
    for (final indice in [1, 2, 0]) {
      await tester.tap(find.widgetWithText(NavigationDestination, destinos[indice]));
      await tester.pumpAndSettle();
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, indice);
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, indice);
    }
    var salidas = 0;
    await tester.pumpWidget(InvenTrackApp(apiService: servicio, salir: () => salidas++));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar sesión'));
    expect(salidas, 1);
  });

  testWidgets('El acceso usa la paleta activa en claro y oscuro', (tester) async {
    final modoInicial = modoTema.value;
    addTearDown(() => modoTema.value = modoInicial);
    modoTema.value = ThemeMode.light;
    await tester.pumpWidget(const SesionIndividual());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.extension<InvenTrackColors>(), InvenTrackColors.light);
    expect(app.darkTheme!.extension<InvenTrackColors>(), InvenTrackColors.dark);
    for (final paleta in [InvenTrackColors.light, InvenTrackColors.dark]) {
      if (paleta == InvenTrackColors.dark) {
        await tester.tap(find.byTooltip('Cambiar a modo oscuro'));
        await tester.pumpAndSettle();
      }
      final titulo = tester.widget<Text>(find.text('Bienvenido a InvenTrack'));
      expect(titulo.style!.color, paleta.ink);
      final etiqueta = tester.element(find.text('Ingresar'));
      final texto = DefaultTextStyle.of(etiqueta).style.color!;
      final fondo = etiqueta.findAncestorWidgetOfExactType<Material>()!.color!;
      expect(contraste(texto, fondo), greaterThanOrEqualTo(4.5));
      final colores = Theme.of(etiqueta).colorScheme;
      for (final color in [colores.primary, colores.secondary, etiqueta.aviso]) {
        final tinte = Color.alphaBlend(color.withValues(alpha: 0.11), paleta.surface);
        expect(contraste(color, tinte), greaterThanOrEqualTo(4.5));
      }
    }
  });

  testWidgets(
    'Flujo basico de productos e inventario con API simulada',
    (WidgetTester tester) async {
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
          final payload =
              jsonDecode(request.body) as Map<String, dynamic>;

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

      // Entrar al catálogo.
      await tester.tap(find.text('Productos'));
      await tester.pumpAndSettle();

      // Crear un producto.
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

      // Comprobar producto registrado.
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

      // Buscar el producto en la lista visual.
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

      // Seleccionar producto.
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

      // Buscar el botón de entrada.
      final botonEntrada = find.widgetWithText(
        FilledButton,
        'Registrar Entrada',
      );

      await tester.scrollUntilVisible(
        botonEntrada,
        200,
        scrollable: inventarioScroll,
      );

      // Desplazar el contenido hacia arriba para
      // evitar que lo tape la barra inferior.
      // Esta operación no espera animaciones externas.
      await tester.drag(
        inventarioScroll,
        const Offset(0, -230),
      );

      await tester.pumpAndSettle();

      // Pulsar el botón de entrada.
      expect(
        botonEntrada,
        findsOneWidget,
      );

      await tester.tap(botonEntrada);
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

      // Verificar los datos obtenidos de la API.
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
            .movimientosRecientes.first.cantidad,
        12,
      );

      expect(
        inventarioProvider
            .movimientosRecientes.first.stockFinal,
        12,
      );

      // Verificar tarjeta de stock.
      await tester.scrollUntilVisible(
        find.text('Stock disponible'),
        200,
        scrollable: inventarioScroll,
      );

      expect(
        find.text('Stock disponible'),
        findsOneWidget,
      );

      // Verificar tarjeta de movimiento.
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
