import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/providers/inventario_provider.dart';
import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/widgets/movimiento_card.dart';
import 'package:inventrack/widgets/movimiento_dialog.dart';
import 'package:inventrack/widgets/stock_card.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final _productoIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _productoIdController.dispose();
    super.dispose();
  }

  String get _productoId => _productoIdController.text.trim();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final productos = context.watch<ProductosProvider>().productos;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & actions section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Gestión de Inventario',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _productoIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID del Producto',
                        hintText: 'Ingresa el ID del producto (ej: PROD-001)',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => _consultarStock(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un ID de producto';
                        }
                        return null;
                      },
                    ),
                    if (productos.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: productos
                            .where((p) => p.activo)
                            .map(
                              (p) => ActionChip(
                                avatar: const Icon(Icons.tag, size: 16),
                                label: Text('${p.id} · ${p.nombre}'),
                                onPressed: () {
                                  _productoIdController.text = p.id;
                                  _consultarStock();
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed:
                          provider.isLoading ? null : _consultarStock,
                      icon: const Icon(Icons.inventory),
                      label: const Text('Consultar Stock'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : () => _registrarMovimiento(
                                      context,
                                      'Registrar Entrada',
                                      true,
                                    ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Registrar Entrada'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : () => _registrarMovimiento(
                                      context,
                                      'Registrar Salida',
                                      false,
                                    ),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Registrar Salida'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Loading indicator
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),

          // Stock card
          if (provider.stockActual != null && !provider.isLoading) ...[
            StockCard(stock: provider.stockActual!),
            const SizedBox(height: 16),
          ],

          // Recent movements
          if (provider.movimientosRecientes.isNotEmpty) ...[
            Text(
              'Movimientos Recientes',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...provider.movimientosRecientes.map(
              (mov) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MovimientoCard(movimiento: mov),
              ),
            ),
          ],

          // Empty state for inventory
          if (!provider.isLoading &&
              provider.stockActual == null &&
              provider.movimientosRecientes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.warehouse_outlined,
                    size: 80,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Consulta o registra movimientos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa el ID de un producto arriba para consultar stock o registrar entradas/salidas',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _consultarStock() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final provider = context.read<InventarioProvider>();

    final stock = await provider.consultarStock(_productoId);
    if (!mounted) return;

    if (stock == null && provider.hasError) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _registrarMovimiento(
    BuildContext context,
    String titulo,
    bool esEntrada,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final provider = context.read<InventarioProvider>();

    final cantidad = await showDialog<int>(
      context: context,
      builder: (_) => MovimientoDialog(titulo: titulo),
    );

    if (cantidad == null || !mounted) return;

    final resultado = esEntrada
        ? await provider.registrarEntrada(_productoId, cantidad)
        : await provider.registrarSalida(_productoId, cantidad);

    if (!mounted) return;

    if (resultado != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            esEntrada
                ? 'Entrada de ${resultado.cantidad} unidades registrada (stock: ${resultado.stockFinal})'
                : 'Salida de ${resultado.cantidad} unidades registrada (stock: ${resultado.stockFinal})',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'No se pudo registrar el movimiento',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
    }
  }
}
