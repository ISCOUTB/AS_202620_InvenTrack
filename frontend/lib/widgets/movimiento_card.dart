import 'package:flutter/material.dart';

import 'package:inventrack/models/movimiento.dart';

class MovimientoCard extends StatelessWidget {
  const MovimientoCard({super.key, required this.movimiento});

  final MovimientoResponse movimiento;

  bool get _esEntrada =>
      movimiento.tipo.toUpperCase() == 'ENTRADA';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _esEntrada ? Colors.green : Colors.orange;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            _esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Text(
          movimiento.tipo.toUpperCase(),
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Producto: ${movimiento.productoId} · Cantidad: ${movimiento.cantidad}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Stock final',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              '${movimiento.stockFinal}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
