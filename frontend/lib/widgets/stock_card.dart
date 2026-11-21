
import 'package:flutter/material.dart';

import 'package:inventrack/models/stock.dart';
import 'package:inventrack/ui/inventrack_style.dart';

class StockCard extends StatelessWidget {
  const StockCard({
    super.key,
    required this.stock,
  });

  final Stock stock;

  Color get _colorEstado {
    if (stock.cantidad > 10) {
      return InvenTrackStyle.emerald;
    }

    if (stock.cantidad > 0) {
      return InvenTrackStyle.orange;
    }

    return const Color(0xFFE45454);
  }

  String get _textoEstado {
    if (stock.cantidad > 10) {
      return 'Disponible';
    }

    if (stock.cantidad > 0) {
      return 'Stock bajo';
    }

    return 'Sin existencias';
  }

  IconData get _iconoEstado {
    if (stock.cantidad > 10) {
      return Icons.check_circle_outline_rounded;
    }

    if (stock.cantidad > 0) {
      return Icons.warning_amber_rounded;
    }

    return Icons.error_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado;

    return SurfacePanel(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la tarjeta.
          Row(
            children: [
              SoftIcon(
                Icons.inventory_2_rounded,
                color: color,
                size: 52,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESUMEN DE EXISTENCIAS',
                      style: TextStyle(
                        color: InvenTrackStyle.muted,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Producto: ${stock.productoId}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: InvenTrackStyle.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 19),

          const Divider(
            color: InvenTrackStyle.outline,
            height: 1,
          ),

          const SizedBox(height: 19),

          // Cantidad disponible.
          const Text(
            'Stock disponible',
            style: TextStyle(
              color: InvenTrackStyle.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  '${stock.cantidad}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 39,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: InvenTrackStyle.ink,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'unidades',
                  style: TextStyle(
                    color: InvenTrackStyle.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 19),

          // Estado visual.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  _iconoEstado,
                  color: color,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _textoEstado,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  Icons.circle,
                  color: color,
                  size: 9,
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Cantidad obtenida de la última consulta o movimiento registrado.',
            style: TextStyle(
              color: InvenTrackStyle.muted,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
