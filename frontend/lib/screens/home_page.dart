import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/models/producto.dart';
import 'package:inventrack/providers/health_provider.dart';
import 'package:inventrack/providers/inventario_provider.dart';
import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/screens/inventario_page.dart';
import 'package:inventrack/screens/gestion_page.dart';
import 'package:inventrack/screens/productos_page.dart';
import 'package:inventrack/ui/inventrack_style.dart';
import 'package:inventrack/widgets/crear_producto_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.salir});

  final VoidCallback? salir;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HealthProvider>().checkHealth();
      context.read<ProductosProvider>().cargarProductos();
    });
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_rounded,
              color: InvenTrackStyle.emerald,
              size: 27,
            ),
            const SizedBox(width: 9),
            Text(
              'InvenTrack',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: context.ink,
              ),
            ),
          ],
        ),
        actions: [
          const BotonModoTema(),
          IconButton(
            tooltip: 'Gestión',
            icon: const Icon(Icons.business_center_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const GestionPage()),
            ),
          ),
          IconButton(
            tooltip: health.isHealthy
                ? 'Servicio disponible'
                : 'Comprobar conexión',
            onPressed: health.isChecking
                ? null
                : () => context
                    .read<HealthProvider>()
                    .checkHealth(),
            icon: Icon(
              health.isChecking
                  ? Icons.sync
                  : health.isHealthy
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
              color: health.isChecking
                  ? context.muted
                  : health.isHealthy
                      ? InvenTrackStyle.emerald
                      : InvenTrackStyle.orange,
            ),
          ),
          if (widget.salir != null)
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: widget.salir,
              icon: const Icon(Icons.logout_rounded),
            ),
          const SizedBox(width: 8),
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
        onDestinationSelected: _selectPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.warehouse_outlined),
            selectedIcon: Icon(Icons.warehouse_rounded),
            label: 'Inventario',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<int> onNavigate;

  Future<void> _actualizar(BuildContext context) async {
    await Future.wait([
      context.read<HealthProvider>().checkHealth(),
      context.read<ProductosProvider>().cargarProductos(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductosProvider>();
    final inventario = context.watch<InventarioProvider>();
    final health = context.watch<HealthProvider>();

    final activos = productos.productos
        .where((producto) => producto.activo)
        .length;

    final stockConsultado = inventario.stockCache.values
        .fold<int>(0, (total, cantidad) => total + cantidad);

    return RefreshIndicator(
      onRefresh: () => _actualizar(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        children: [
          Text(
            'Resumen de inventario',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: context.ink,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Todo lo importante de tu negocio, en un solo lugar.',
            style: TextStyle(
              fontSize: 13,
              color: context.muted,
            ),
          ),
          const SizedBox(height: 20),

          _WelcomeCard(
            onOpen: () => onNavigate(2),
          ),

          const SizedBox(height: 17),

          _ConnectionPanel(health: health),

          const SizedBox(height: 26),

          const SectionHeading(
            'Tu inventario en números',
            subtitle: 'Resumen de la información disponible',
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatTile(
                label: 'Productos activos',
                value: '$activos',
                icon: Icons.inventory_2_outlined,
                color: InvenTrackStyle.emerald,
              ),
              StatTile(
                label: 'Stock consultado',
                value: '$stockConsultado',
                icon: Icons.warehouse_outlined,
                color: InvenTrackStyle.orange,
              ),
              StatTile(
                label: 'Movimientos recientes',
                value: '${inventario.movimientosRecientes.length}',
                icon: Icons.swap_vert_rounded,
                color: InvenTrackStyle.lavender,
              ),
              StatTile(
                label: 'Productos registrados',
                value: '${productos.productos.length}',
                icon: Icons.category_outlined,
                color: InvenTrackStyle.deepGreen,
              ),
            ],
          ),

          const SizedBox(height: 26),

          const SectionHeading(
            'Acciones rápidas',
            subtitle: 'Gestiona tu negocio en pocos pasos',
          ),
          const SizedBox(height: 13),

          _ActionTile(
            icon: Icons.add_box_rounded,
            color: InvenTrackStyle.emerald,
            title: 'Nuevo Producto',
            subtitle: 'Agrega un producto al catálogo',
            onTap: () => _crearProducto(context),
          ),

          const SizedBox(height: 11),

          _ActionTile(
            icon: Icons.warehouse_rounded,
            color: InvenTrackStyle.orange,
            title: 'Gestionar inventario',
            subtitle: 'Consulta stock, entradas y salidas',
            onTap: () => onNavigate(2),
          ),

          const SizedBox(height: 26),

          SectionHeading(
            'Productos recientes',
            subtitle: 'Últimos productos del catálogo',
            trailing: TextButton(
              onPressed: () => onNavigate(1),
              child: const Text('Ver todos'),
            ),
          ),
          const SizedBox(height: 13),

          if (productos.productos.isEmpty)
            const EmptyPanel(
              icon: Icons.inventory_2_outlined,
              title: 'Aún no hay productos',
              subtitle:
                  'Agrega tu primer producto para comenzar a gestionar el inventario.',
            )
          else
            SurfacePanel(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Column(
                children: productos.productos
                    .take(3)
                    .map(
                      (producto) => ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        leading: const SoftIcon(
                          Icons.inventory_2_outlined,
                          size: 42,
                        ),
                        title: Text(
                          producto.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.ink,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${producto.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: StatusTag(
                          producto.activo ? 'Activo' : 'Inactivo',
                          color: producto.activo
                              ? InvenTrackStyle.emerald
                              : context.muted,
                        ),
                        onTap: () => onNavigate(1),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _crearProducto(BuildContext context) async {
    final request = await showDialog<CrearProductoRequest>(
      context: context,
      builder: (_) => const CrearProductoDialog(),
    );

    if (request == null || !context.mounted) return;

    final provider = context.read<ProductosProvider>();

    final creado = await provider.crearProducto(
      request.id,
      request.nombre,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          creado == null
              ? provider.errorMessage ??
                  'No se pudo crear el producto'
              : 'Producto "${creado.nombre}" creado exitosamente',
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: InvenTrackStyle.heroGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -55,
              top: -60,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x25FFFFFF),
                    width: 32,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x28FFFFFF),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'CENTRO DE CONTROL',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.3,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Tu inventario,\nbajo control.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.18,
                      letterSpacing: -0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Organiza tus productos y registra cada movimiento fácilmente.',
                    style: TextStyle(
                      color: Color(0xFFD0E9E0),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 19),
                  FilledButton.icon(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: InvenTrackStyle.ink,
                    ),
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: const Text('Abrir inventario'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({required this.health});

  final HealthProvider health;

  @override
  Widget build(BuildContext context) {
    final conectado = health.isHealthy;
    final comprobando = health.isChecking;

    final color = comprobando
        ? context.muted
        : conectado
            ? InvenTrackStyle.emerald
            : InvenTrackStyle.orange;

    return SurfacePanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SoftIcon(
            conectado
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            color: color,
            size: 45,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comprobando
                      ? 'Verificando conexión'
                      : conectado
                          ? 'Servicio conectado'
                          : 'Servicio no disponible',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: context.ink,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Estado de conexión con la API',
                  style: TextStyle(
                    color: context.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            conectado
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: SurfacePanel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SoftIcon(
                icon,
                color: color,
                size: 49,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: context.ink,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
