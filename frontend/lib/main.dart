import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/providers/health_provider.dart';
import 'package:inventrack/providers/inventario_provider.dart';
import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/screens/home_page.dart';
import 'package:inventrack/services/api_service.dart';

void main() {
  runApp(const InvenTrackApp());
}

class InvenTrackApp extends StatelessWidget {
  const InvenTrackApp({super.key, this.apiService});

  final ApiService? apiService;

  @override
  Widget build(BuildContext context) {
    final service = apiService ?? ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthProvider(service)),
        ChangeNotifierProvider(create: (_) => ProductosProvider(service)),
        ChangeNotifierProvider(create: (_) => InventarioProvider(service)),
      ],
      child: MaterialApp(
        title: 'InvenTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
