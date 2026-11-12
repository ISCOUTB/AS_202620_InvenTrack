import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/providers/health_provider.dart';
import 'package:inventrack/screens/productos_page.dart';
import 'package:inventrack/screens/inventario_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    ProductosPage(),
    InventarioPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthProvider>().checkHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('InvenTrack'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              onPressed: healthProvider.isChecking
                  ? null
                  : () => context.read<HealthProvider>().checkHealth(),
              tooltip: _healthTooltip(healthProvider),
              icon: Icon(
                Icons.circle,
                size: 14,
                color: _healthColor(healthProvider),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.warehouse_outlined),
            selectedIcon: Icon(Icons.warehouse),
            label: 'Inventario',
          ),
        ],
      ),
    );
  }

  Color _healthColor(HealthProvider provider) {
    if (provider.isChecking) return Colors.grey;
    if (provider.isHealthy) return Colors.green;
    return Colors.red;
  }

  String _healthTooltip(HealthProvider provider) {
    if (provider.isChecking) return 'Verificando conexión...';
    if (provider.isHealthy) return 'Servicio disponible (toca para reverificar)';
    return provider.lastError ?? 'Servicio no disponible (toca para reintentar)';
  }
}
