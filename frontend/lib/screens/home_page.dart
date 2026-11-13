import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/providers/health_provider.dart';
import 'package:inventrack/providers/inventario_provider.dart';
import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/models/producto.dart';
import 'package:inventrack/screens/productos_page.dart';
import 'package:inventrack/screens/inventario_page.dart';
import 'package:inventrack/widgets/crear_producto_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthProvider>().checkHealth();
      context.read<ProductosProvider>().cargarProductos();
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardPage(onNavigate: _selectPage),
          const ProductosPage(),
          const InventarioPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
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

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

class DashboardPage extends StatelessWidget {
    const DashboardPage({super.key, required this.onNavigate});

    final ValueChanged<int> onNavigate;

    @override
    Widget build(BuildContext context) {
      final productos = context.watch<ProductosProvider>();
      final inventario = context.watch<InventarioProvider>();
      final health = context.watch<HealthProvider>();
      final theme = Theme.of(context);
      final activos = productos.productos.where((producto) => producto.activo).length;
      final totalStock =
          inventario.stockCache.values.fold<int>(0, (total, stock) => total + stock);

      return RefreshIndicator(
        onRefresh: health.checkHealth,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Resumen de inventario',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Administra tus productos de forma simple y rápida.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _ConnectionCard(health: health),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SummaryCard(
                  label: 'Productos activos',
                  value: '$activos',
                  icon: Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary,
                ),
                _SummaryCard(
                  label: 'Stock consultado',
                  value: '$totalStock',
                  icon: Icons.warehouse_outlined,
                  color: Colors.deepOrange,
                ),
                _SummaryCard(
                  label: 'Movimientos',
                  value: '${inventario.movimientosRecientes.length}',
                  icon: Icons.swap_vert,
                  color: Colors.indigo,
                ),
                _SummaryCard(
                  label: 'Productos registrados',
                  value: '${productos.productos.length}',
                  icon: Icons.category_outlined,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Acciones rápidas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _QuickAction(
              icon: Icons.add_box_outlined,
              title: 'Nuevo Producto',
              subtitle: 'Agrega un producto al catálogo',
              onTap: () => _showCreateProductDialog(context),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.warehouse_outlined,
              title: 'Gestionar inventario',
              subtitle: 'Consulta stock y registra movimientos',
              onTap: () => onNavigate(2),
            ),
            if (productos.productos.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Productos recientes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...productos.productos.take(3).map(
                    (producto) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.inventory_2_outlined),
                        ),
                        title: Text(producto.nombre),
                        subtitle: Text('ID: ${producto.id}'),
                        trailing: Icon(
                          producto.activo
                              ? Icons.check_circle_outline
                              : Icons.block_outlined,
                          color: producto.activo ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ),
            ],
            if (productos.productos.isEmpty) ...[
              const SizedBox(height: 24),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No hay productos registrados',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Crea el primero para comenzar.',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    Future<void> _showCreateProductDialog(BuildContext context) async {
      final request = await showDialog<CrearProductoRequest>(
        context: context,
        builder: (_) => const CrearProductoDialog(),
      );
      if (request == null || !context.mounted) return;

      final provider = context.read<ProductosProvider>();
      final created = await provider.crearProducto(request.id, request.nombre);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created == null
                ? provider.errorMessage ?? 'No se pudo crear el producto'
                : 'Producto "${created.nombre}" creado exitosamente',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  class _ConnectionCard extends StatelessWidget {
    const _ConnectionCard({required this.health});

    final HealthProvider health;

    @override
    Widget build(BuildContext context) {
      final connected = health.isHealthy;
      final color = connected ? Colors.green : Colors.orange;
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(28),
            child: Icon(
              connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: color,
            ),
          ),
          title: Text(connected ? 'Servicio conectado' : 'Servicio no verificado'),
          subtitle: Text(
            connected
                ? 'La API de InvenTrack está disponible'
                : 'Toca el indicador superior para comprobar la conexión',
          ),
        ),
      );
    }
  }

  class _SummaryCard extends StatelessWidget {
    const _SummaryCard({
      required this.label,
      required this.value,
      required this.icon,
      required this.color,
    });

    final String label;
    final String value;
    final IconData icon;
    final Color color;

    @override
    Widget build(BuildContext context) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }
  }

  class _QuickAction extends StatelessWidget {
    const _QuickAction({
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
    });

    final IconData icon;
    final String title;
    final String subtitle;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
      return Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            child: Icon(icon),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
    }
  }
