import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inventrack/providers/inventario_provider.dart';
import 'package:inventrack/providers/productos_provider.dart';
import 'package:inventrack/ui/inventrack_style.dart';
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

  String get _productoId =>
      _productoIdController.text.trim();

  @override
  Widget build(BuildContext context) {
    final inventario = context.watch<InventarioProvider>();
    final productos = context.watch<ProductosProvider>()
        .productos
        .where((producto) => producto.activo)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 35),
      children: [
        const Text(
          'Mi inventario',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: InvenTrackStyle.ink,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Controla las existencias y movimientos de tus productos.',
          style: TextStyle(
            fontSize: 13,
            color: InvenTrackStyle.muted,
          ),
        ),
        const SizedBox(height: 20),

        // Encabezado principal.
        const _InventoryHero(),

        const SizedBox(height: 25),

        const SectionHeading(
          'Consultar producto',
          subtitle: 'Busca mediante su identificador',
        ),
        const SizedBox(height: 13),

        SurfacePanel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Identificador del producto',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: InvenTrackStyle.ink,
                  ),
                ),
                const SizedBox(height: 11),

                TextFormField(
                  controller: _productoIdController,
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (_) => _consultarStock(),
                  decoration: const InputDecoration(
                    labelText: 'ID del Producto',
                    hintText: 'Ej: PROD-001',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: InvenTrackStyle.emerald,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresa un ID de producto';
                    }
                    return null;
                  },
                ),

                if (productos.isNotEmpty) ...[
                  const SizedBox(height: 17),
                  const Text(
                    'PRODUCTOS DISPONIBLES',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: InvenTrackStyle.muted,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: productos.map((producto) {
                      return ActionChip(
                        avatar: const Icon(
                          Icons.tag_rounded,
                          size: 15,
                          color: InvenTrackStyle.emerald,
                        ),
                        label: Text(
                          '${producto.id} · ${producto.nombre}',
                          style: const TextStyle(
                            fontSize: 11.5,
                          ),
                        ),
                        backgroundColor:
                            InvenTrackStyle.mint,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        onPressed: inventario.isLoading
                            ? null
                            : () {
                                _productoIdController.text =
                                    producto.id;
                                _consultarStock();
                              },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 18),

                FilledButton.icon(
                  onPressed: inventario.isLoading
                      ? null
                      : _consultarStock,
                  icon: const Icon(
                    Icons.search_rounded,
                  ),
                  label: const Text(
                    'Consultar Stock',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 26),

        const SectionHeading(
          'Movimientos de inventario',
          subtitle: 'Registra entradas y salidas de mercancía',
        ),
        const SizedBox(height: 13),

        SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  SoftIcon(
                    Icons.swap_vert_rounded,
                    size: 47,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Registrar movimiento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: InvenTrackStyle.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              const Text(
                'Primero selecciona un producto mediante su ID. Después registra la cantidad.',
                style: TextStyle(
                  color: InvenTrackStyle.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 17),

              // Entrada.
              FilledButton.icon(
                onPressed: inventario.isLoading
                    ? null
                    : () => _registrarMovimiento(
                          'Registrar Entrada',
                          true,
                        ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      InvenTrackStyle.emerald,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                ),
                label: const Text(
                  'Registrar Entrada',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Salida.
              FilledButton.icon(
                onPressed: inventario.isLoading
                    ? null
                    : () => _registrarMovimiento(
                          'Registrar Salida',
                          false,
                        ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      InvenTrackStyle.orange,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                ),
                label: const Text(
                  'Registrar Salida',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (inventario.isLoading) ...[
          const SizedBox(height: 20),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],

        if (inventario.hasError) ...[
          const SizedBox(height: 16),
          SurfacePanel(
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: InvenTrackStyle.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    inventario.errorMessage ??
                        'Ocurrió un error.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: InvenTrackStyle.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Existencias consultadas.
        if (inventario.stockActual != null &&
            !inventario.isLoading) ...[
          const SizedBox(height: 26),
          const SectionHeading(
            'Existencias actuales',
            subtitle: 'Resultado de la última consulta',
          ),
          const SizedBox(height: 12),
          StockCard(stock: inventario.stockActual!),
        ],

        // Historial reciente.
        if (inventario.movimientosRecientes.isNotEmpty) ...[
          const SizedBox(height: 26),
          SectionHeading(
            'Movimientos recientes',
            subtitle:
                '${inventario.movimientosRecientes.length} operaciones registradas en esta sesión',
          ),
          const SizedBox(height: 12),
          ...inventario.movimientosRecientes.map(
            (movimiento) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MovimientoCard(
                movimiento: movimiento,
              ),
            ),
          ),
        ],

        // Estado sin consultas.
        if (!inventario.isLoading &&
            inventario.stockActual == null &&
            inventario.movimientosRecientes.isEmpty &&
            !inventario.hasError) ...[
          const SizedBox(height: 24),
          const EmptyPanel(
            icon: Icons.warehouse_outlined,
            title: 'Tu inventario está listo',
            subtitle:
                'Selecciona un producto para consultar sus existencias o registrar un movimiento.',
          ),
        ],
      ],
    );
  }

  Future<void> _consultarStock() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<InventarioProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final productoId = _productoId;

    final stock = await provider.consultarStock(productoId);

    if (!mounted) return;

    if (stock == null && provider.hasError) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: InvenTrackStyle.orange,
          content: Text(
            provider.errorMessage ??
                'No se pudo consultar el producto.',
          ),
        ),
      );
    }
  }

  Future<void> _registrarMovimiento(
    String titulo,
    bool esEntrada,
  ) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<InventarioProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final productoId = _productoId;

    final cantidad = await showDialog<int>(
      context: context,
      builder: (_) => MovimientoDialog(
        titulo: titulo,
      ),
    );

    if (cantidad == null || !mounted) return;

    final resultado = esEntrada
        ? await provider.registrarEntrada(
            productoId,
            cantidad,
          )
        : await provider.registrarSalida(
            productoId,
            cantidad,
          );

    if (!mounted) return;

    if (resultado != null) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: InvenTrackStyle.deepGreen,
          content: Text(
            esEntrada
                ? 'Entrada de ${resultado.cantidad} unidades registrada (stock: ${resultado.stockFinal})'
                : 'Salida de ${resultado.cantidad} unidades registrada (stock: ${resultado.stockFinal})',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: InvenTrackStyle.orange,
          content: Text(
            provider.errorMessage ??
                'No se pudo registrar el movimiento.',
          ),
        ),
      );
    }
  }
}

// Tarjeta destacada superior.
class _InventoryHero extends StatelessWidget {
  const _InventoryHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: InvenTrackStyle.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -45,
              right: -35,
              child: Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x20FFFFFF),
                    width: 25,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusTag(
                    'CONTROL DE EXISTENCIAS',
                    color: Color(0xFF5BE0B8),
                  ),
                  SizedBox(height: 19),
                  Text(
                    'Todo en orden,\ntodo bajo control.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 9),
                  Text(
                    'Consulta tus productos y registra cada movimiento de manera sencilla.',
                    style: TextStyle(
                      color: Color(0xFFD5EAE4),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
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
