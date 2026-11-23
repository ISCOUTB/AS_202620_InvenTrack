
import 'package:flutter/material.dart';

/// Estilos visuales de InvenTrack.
abstract final class InvenTrackStyle {
  static const ink = Color(0xFF102D31);
  static const emerald = Color(0xFF05977B);
  static const deepGreen = Color(0xFF087D6D);
  static const mint = Color(0xFFE0F6EE);
  static const canvas = Color(0xFFF3F8F6);
  static const muted = Color(0xFF738782);
  static const outline = Color(0xFFE3EFEB);
  static const orange = Color(0xFFE88954);
  static const lavender = Color(0xFF7773D6);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF102D31),
      Color(0xFF145148),
    ],
  );
}

/// Paleta que cambia entre modo claro y oscuro.
@immutable
class InvenTrackColors extends ThemeExtension<InvenTrackColors> {
  const InvenTrackColors({
    required this.ink,
    required this.muted,
    required this.outline,
    required this.canvas,
    required this.surface,
    required this.mint,
    required this.shadow,
  });

  final Color ink;
  final Color muted;
  final Color outline;
  final Color canvas;
  final Color surface;
  final Color mint;
  final Color shadow;

  static const light = InvenTrackColors(
    ink: InvenTrackStyle.ink,
    muted: InvenTrackStyle.muted,
    outline: InvenTrackStyle.outline,
    canvas: InvenTrackStyle.canvas,
    surface: Colors.white,
    mint: InvenTrackStyle.mint,
    shadow: Color(0x0A183C33),
  );

  static const dark = InvenTrackColors(
    ink: Color(0xFFE6F2EF),
    muted: Color(0xFF93A8A3),
    outline: Color(0xFF263D40),
    canvas: Color(0xFF0C1819),
    surface: Color(0xFF142528),
    mint: Color(0xFF123F38),
    shadow: Color(0x66000000),
  );

  @override
  InvenTrackColors copyWith({
    Color? ink,
    Color? muted,
    Color? outline,
    Color? canvas,
    Color? surface,
    Color? mint,
    Color? shadow,
  }) {
    return InvenTrackColors(
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      outline: outline ?? this.outline,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      mint: mint ?? this.mint,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  InvenTrackColors lerp(InvenTrackColors? other, double t) {
    if (other == null) return this;
    return InvenTrackColors(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Atajos para leer los colores del tema activo.
extension InvenTrackContext on BuildContext {
  InvenTrackColors get _paleta =>
      Theme.of(this).extension<InvenTrackColors>() ?? InvenTrackColors.light;

  Color get ink => _paleta.ink;
  Color get muted => _paleta.muted;
  Color get outline => _paleta.outline;
  Color get canvas => _paleta.canvas;
  Color get surface => _paleta.surface;
  Color get mint => _paleta.mint;
  Color get watchShadow => _paleta.shadow;
}

/// Modo de tema elegido por la persona. Por defecto sigue al sistema.
final ValueNotifier<ThemeMode> modoTema = ValueNotifier(ThemeMode.system);

/// Botón que alterna entre modo claro y oscuro.
class BotonModoTema extends StatelessWidget {
  const BotonModoTema({super.key});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: oscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      icon: Icon(
        oscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
      onPressed: () {
        modoTema.value = oscuro ? ThemeMode.light : ThemeMode.dark;
      },
    );
  }
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.outline,
        ),
        boxShadow: [
          BoxShadow(
            color: context.watchShadow,
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: context.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class SoftIcon extends StatelessWidget {
  const SoftIcon(
    this.icon, {
    super.key,
    this.color = InvenTrackStyle.emerald,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.48,
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
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
    return SurfacePanel(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          SoftIcon(icon, color: color, size: 38),
          const SizedBox(height: 13),
          Text(
            value,
            style: TextStyle(
              fontSize: 27,
              color: context.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusTag extends StatelessWidget {
  const StatusTag(
    this.label, {
    super.key,
    this.color = InvenTrackStyle.emerald,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 38,
          horizontal: 8,
        ),
        child: Column(
          children: [
            SoftIcon(icon, size: 66),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: context.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
