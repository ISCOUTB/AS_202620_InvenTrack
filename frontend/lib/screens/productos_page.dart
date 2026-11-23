import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/models/producto.dart';
import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/ui/inventrack_style.dart';
import 'package:inventrack/widgets/crear_producto_dialog.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final TextEditingController _busquedaController =
      TextEditingController();

  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();

    _busquedaController.addListener(_actualizarBusqueda);
  }

  void _actualizarBusqueda() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _busquedaController.removeListener(_actualizarBusqueda);
    _busquedaController.dispose();
    super.dispose();
  }

  List<Producto> _filtrarProductos(
    List<Producto> productos,
  ) {
    final busqueda =
        _busquedaController.text.trim().toLowerCase();

    return productos.where((producto) {
      final coincideBusqueda =
          producto.nombre.toLowerCase().contains(busqueda) ||
          producto.id.toLowerCase().contains(busqueda);

      final coincideEstado = _filtro == 'Todos' ||
          (_filtro == 'Activos' && producto.activo) ||
          (_filtro == 'Inactivos' && !producto.activo);

      return coincideBusqueda && coincideEstado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductosProvider>();
    final productos = provider.productos;
    final filtrados = _filtrarProductos(productos);

    final activos =
        productos.where((producto) => producto.activo).length;

    final inactivos = productos.length - activos;

    return Scaffold(
      backgroundColor: context.canvas,
      body: RefreshIndicator(
        onRefresh: () => provider.cargarProductos(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 105),
          children: [
            Text(
              'Mis productos',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
                color: context.ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Organiza y administra tu catálogo fácilmente.',
              style: TextStyle(
                color: context.muted,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 22),

            // Resumen del catálogo.
            SurfacePanel(
              child: Row(
                children: [
                  const SoftIcon(
                    Icons.inventory_2_rounded,
                    size: 52,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total de productos',
                          style: TextStyle(
                            color: context.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${productos.length}',
                          style: TextStyle(
                            color: context.ink,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusTag(
                    '$activos activos',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const SectionHeading(
              'Explorar catálogo',
              subtitle: 'Busca por nombre o identificador',
            ),

            const SizedBox(height: 13),

            // Buscador local.
            TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.muted,
                ),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _busquedaController.clear,
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 15),

            // Filtros.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FiltroChip(
                    titulo: 'Todos (${productos.length})',
                    seleccionado: _filtro == 'Todos',
                    onTap: () {
                      setState(() => _filtro = 'Todos');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    titulo: 'Activos ($activos)',
                    seleccionado: _filtro == 'Activos',
                    onTap: () {
                      setState(() => _filtro = 'Activos');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    titulo: 'Inactivos ($inactivos)',
                    seleccionado: _filtro == 'Inactivos',
                    onTap: () {
                      setState(() => _filtro = 'Inactivos');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 23),

            SectionHeading(
              'Listado de productos',
              subtitle:
                  '${filtrados.length} productos encontrados',
            ),

            const SizedBox(height: 14),

            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            if (provider.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SurfacePanel(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: InvenTrackStyle.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          provider.errorMessage ??
                              'Ocurrió un error.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!provider.isLoading && filtrados.isEmpty)
              EmptyPanel(
                icon: Icons.search_off_rounded,
                title: productos.isEmpty
                    ? 'No hay productos registrados'
                    : 'No encontramos resultados',
                subtitle: productos.isEmpty
                    ? 'Agrega tu primer producto para comenzar.'
                    : 'Prueba otra búsqueda o cambia el filtro.',
              ),

            if (!provider.isLoading)
              ...filtrados.map(
                (producto) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _ProductoCard(
                    producto: producto,
                    onDelete: () =>
                        _confirmarEliminar(context, producto),
                  ),
                ),
              ),
          ],
        ),
      ),

      // Botón principal.
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nuevo_producto',
        backgroundColor: InvenTrackStyle.emerald,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => _crearProducto(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuevo Producto',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
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
          creado != null
              ? 'Producto "${creado.nombre}" creado exitosamente'
              : provider.errorMessage ??
                  'No se pudo crear el producto.',
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    Producto producto,
  ) async {
    final provider = context.read<ProductosProvider>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: InvenTrackStyle.orange,
        ),
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Deseas eliminar o desactivar "${producto.nombre}" (${producto.id})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) {
      return;
    }

    final respuesta =
        await provider.eliminarProducto(producto.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          respuesta?.mensaje ??
              provider.errorMessage ??
              'No se pudo modificar el producto.',
        ),
      ),
    );
  }
}

// Botones de filtrado.
class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.titulo,
    required this.seleccionado,
    required this.onTap,
  });

  final String titulo;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(titulo),
      selected: seleccionado,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: context.mint,
      backgroundColor: context.surface,
      side: BorderSide(
        color: seleccionado
            ? InvenTrackStyle.emerald
            : context.outline,
      ),
      labelStyle: TextStyle(
        color: seleccionado
            ? InvenTrackStyle.deepGreen
            : context.muted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    );
  }
}

// Tarjeta visual de producto.
class _ProductoCard extends StatelessWidget {
  const _ProductoCard({
    required this.producto,
    required this.onDelete,
  });

  final Producto producto;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = producto.activo
        ? InvenTrackStyle.emerald
        : context.muted;

    return Dismissible(
      key: ValueKey(producto.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDeleteAsync();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      child: SurfacePanel(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            SoftIcon(
              Icons.inventory_2_outlined,
              color: color,
              size: 49,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'ID: ${producto.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.muted,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  StatusTag(
                    producto.activo ? 'Activo' : 'Inactivo',
                    color: color,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar o desactivar producto',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: context.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onDeleteAsync() async {
    onDelete();
  }
}
