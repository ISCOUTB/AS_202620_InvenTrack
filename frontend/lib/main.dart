
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/providers/health_provider.dart';
import 'package:inventrack/providers/inventario_provider.dart';
import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/screens/home_page.dart';
import 'package:inventrack/services/api_service.dart';
import 'package:inventrack/ui/inventrack_style.dart';

// Tema visual general de InvenTrack.
ThemeData crearTemaInvenTrack() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: InvenTrackStyle.emerald,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: InvenTrackStyle.canvas,

    appBarTheme: const AppBarTheme(
      backgroundColor: InvenTrackStyle.canvas,
      foregroundColor: InvenTrackStyle.ink,
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: InvenTrackStyle.outline,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: InvenTrackStyle.emerald,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: InvenTrackStyle.outline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: InvenTrackStyle.outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: InvenTrackStyle.emerald,
          width: 1.8,
        ),
      ),
    ),

    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: InvenTrackStyle.mint,
      elevation: 0,
    ),
  );
}

void main() {
  const individual =
      bool.fromEnvironment('INVENTRACK_AUTH');

  runApp(
    individual
        ? const SesionIndividual()
        : const InvenTrackApp(),
  );
}

// Acceso mediante credencial individual.
class SesionIndividual extends StatefulWidget {
  const SesionIndividual({super.key});

  @override
  State<SesionIndividual> createState() =>
      _SesionIndividualState();
}

class _SesionIndividualState
    extends State<SesionIndividual> {
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
      candidato = ApiService(
        token: campo.text.trim(),
      );

      await candidato.listarProductos();

      if (!mounted) {
        candidato.dispose();
        return;
      }

      campo.clear();

      setState(() {
        servicio = candidato;
      });
    } catch (_) {
      candidato?.dispose();

      if (mounted) {
        setState(() {
          error =
              'Verifica tu credencial y la conexión al servicio.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          esperando = false;
        });
      }
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

          setState(() {
            servicio = null;
          });
        },
      );
    }

    return MaterialApp(
      title: 'Acceder a InvenTrack',
      debugShowCheckedModeBanner: false,
      theme: crearTemaInvenTrack(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('InvenTrack'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: SurfacePanel(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const SoftIcon(
                      Icons.inventory_2_rounded,
                      size: 60,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bienvenido a InvenTrack',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: InvenTrackStyle.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa tu credencial para continuar.',
                      style: TextStyle(
                        color: InvenTrackStyle.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: campo,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Credencial individual',
                        prefixIcon:
                            const Icon(Icons.lock_outline),
                        errorText: error,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: esperando
                          ? null
                          : ingresar,
                      icon: const Icon(
                        Icons.login_rounded,
                      ),
                      label: Text(
                        esperando
                            ? 'Verificando...'
                            : 'Ingresar',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Aplicación principal.
class InvenTrackApp extends StatelessWidget {
  const InvenTrackApp({
    super.key,
    this.apiService,
    this.salir,
  });

  final ApiService? apiService;
  final VoidCallback? salir;

  @override
  Widget build(BuildContext context) {
    final service =
        apiService ?? ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HealthProvider(service),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductosProvider(service),
        ),
        ChangeNotifierProvider(
          create: (_) => InventarioProvider(service),
        ),
      ],
      child: MaterialApp(
        title: 'InvenTrack',
        debugShowCheckedModeBanner: false,
        theme: crearTemaInvenTrack(),
        themeMode: ThemeMode.light,
        home: HomePage(salir: salir),
      ),
    );
  }
}
