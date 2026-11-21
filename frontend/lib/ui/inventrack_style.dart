
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: InvenTrackStyle.outline,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A183C33),
            blurRadius: 22,
            offset: Offset(0, 9),
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
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: InvenTrackStyle.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: InvenTrackStyle.muted,
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
            style: const TextStyle(
              fontSize: 27,
              color: InvenTrackStyle.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: InvenTrackStyle.muted,
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
              style: const TextStyle(
                fontSize: 17,
                color: InvenTrackStyle.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: InvenTrackStyle.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
