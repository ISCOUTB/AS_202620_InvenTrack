import 'package:flutter/material.dart';

import 'package:inventrack/models/movimiento.dart';
import 'package:inventrack/ui/inventrack_style.dart';

class MovimientoCard extends StatelessWidget {
  const MovimientoCard({
    super.key,
    required this.movimiento,
  });

  final MovimientoResponse movimiento;

  bool get _esEntrada =>
      movimiento.tipo.toUpperCase() == 'ENTRADA';

  @override
  Widget build(BuildContext context) {
    final color = _esEntrada
        ? InvenTrackStyle.emerald
        : InvenTrackStyle.orange;

    final titulo = _esEntrada
        ? 'Entrada de mercancía'
        : 'Salida de mercancía';

    final icono = _esEntrada
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;

    return SurfacePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del movimiento.
          Row(
            children: [
              SoftIcon(
                icono,
                color: color,
                size: 47,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: InvenTrackStyle.ink,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'ID ${movimiento.productoId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: InvenTrackStyle.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              StatusTag(
                _esEntrada ? 'Entrada' : 'Salida',
                color: color,
              ),
            ],
          ),

          const SizedBox(height: 17),

          const Divider(
            height: 1,
            color: InvenTrackStyle.outline,
          ),

          const SizedBox(height: 16),

          // Información del movimiento.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cantidad',
                      style: TextStyle(
                        color: InvenTrackStyle.muted,
                        fontSize: 11.5,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          _esEntrada
                              ? Icons.add_rounded
                              : Icons.remove_rounded,
                          color: color,
                          size: 20,
                        ),

                        const SizedBox(width: 4),

                        Flexible(
                          child: Text(
                            '${movimiento.cantidad}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                height: 42,
                width: 1,
                color: InvenTrackStyle.outline,
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stock final',
                      style: TextStyle(
                        color: InvenTrackStyle.muted,
                        fontSize: 11.5,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${movimiento.stockFinal}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: InvenTrackStyle.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Franja inferior.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: color,
                  size: 17,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    _esEntrada
                        ? 'Entrada registrada correctamente'
                        : 'Salida registrada correctamente',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
