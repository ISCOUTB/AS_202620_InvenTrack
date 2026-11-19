import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/providers/health_provider.dart';
import 'package:inventrack/providers/inventario_provider.dart';
import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/screens/home_page.dart';
import 'package:inventrack/services/api_service.dart';

void main() {
  const individual = bool.fromEnvironment('INVENTRACK_AUTH');
  runApp(individual ? const SesionIndividual() : const InvenTrackApp());
}

class SesionIndividual extends StatefulWidget {
  const SesionIndividual({super.key});

  @override
  State<SesionIndividual> createState() => _SesionIndividualState();
}

class _SesionIndividualState extends State<SesionIndividual> {
  final campo = TextEditingController();
  ApiService? servicio;
  String? error;
  bool esperando = false;

  Future<void> ingresar() async {
    setState(() {
      esperando = true;
      error = null;
    });
    ApiService? candidato;
    try {
      candidato = ApiService(token: campo.text.trim());
      await candidato.listarProductos();
      if (!mounted) {
        candidato.dispose();
        return;
      }
      campo.clear();
      setState(() => servicio = candidato);
    } catch (_) {
      candidato?.dispose();
      if (mounted) {
        setState(
            () => error = 'Verifica tu credencial y la conexión al servicio.');
      }
    } finally {
      if (mounted) setState(() => esperando = false);
    }
  }

  @override
  void dispose() {
    campo.dispose();
    servicio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (servicio != null) {
      return InvenTrackApp(
          apiService: servicio,
          salir: () {
            servicio?.dispose();
            setState(() => servicio = null);
          });
    }
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(title: const Text('Acceder a InvenTrack')),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            TextField(
                controller: campo,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                    labelText: 'Credencial individual', errorText: error)),
            FilledButton(
                onPressed: esperando ? null : ingresar,
                child: const Text('Ingresar')),
          ])),
    ));
  }
}

class InvenTrackApp extends StatelessWidget {
  const InvenTrackApp({super.key, this.apiService, this.salir});

  final ApiService? apiService;
  final VoidCallback? salir;

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
        home: HomePage(salir: salir),
      ),
    );
  }
}
