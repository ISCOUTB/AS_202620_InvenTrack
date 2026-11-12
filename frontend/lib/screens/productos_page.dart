import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/models/producto.dart';
import 'package:inventrack/widgets/crear_producto_dialog.dart';

class ProductosPage extends StatelessWidget {
  const ProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductosProvider>();
    final productos = provider.productos;
    final theme = Theme.of(context);

    return Scaffold(
      body: _buildBody(context, provider, productos, theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCrearProductoDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductosProvider provider,
    List<Producto> productos,
    ThemeData theme,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos registrados',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón + para agregar uno',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Placeholder for future refresh logic (e.g., GET /productos)
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: productos.length,
        itemBuilder: (context, index) {
          final producto = productos[index];
          return _ProductoTile(
            producto: producto,
            onDelete: () => _confirmarEliminar(context, producto),
          );
        },
      ),
    );
  }

  Future<void> _showCrearProductoDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final provider = context.read<ProductosProvider>();

    final request = await showDialog<CrearProductoRequest>(
      context: context,
      builder: (_) => const CrearProductoDialog(),
    );

    if (request == null || !context.mounted) return;

    final creado = await provider.crearProducto(request.id, request.nombre);
    if (!context.mounted) return;

    if (creado != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Producto "${creado.nombre}" creado exitosamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Error al crear producto',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    Producto producto,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final provider = context.read<ProductosProvider>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de que deseas eliminar el producto "${producto.nombre}" (${producto.id})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    final response = await provider.eliminarProducto(producto.id);
    if (!context.mounted) return;

    if (response != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(response.mensaje),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Error al eliminar producto',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
    }
  }
}

class _ProductoTile extends StatelessWidget {
  const _ProductoTile({
    required this.producto,
    required this.onDelete,
  });

  final Producto producto;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(producto.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.colorScheme.error,
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Don't dismiss automatically; let the provider handle it
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: producto.activo
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            producto.id.substring(0, producto.id.length.clamp(0, 2)).toUpperCase(),
            style: TextStyle(
              color: producto.activo
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.outline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(producto.nombre),
        subtitle: Text('ID: ${producto.id}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                producto.activo ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 12,
                  color: producto.activo
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.outline,
                ),
              ),
              backgroundColor: producto.activo
                  ? theme.colorScheme.tertiaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar o desactivar producto',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
