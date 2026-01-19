import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const InfoPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final resolvedColor = color ?? theme.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: resolvedColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: resolvedColor),
        ),
      ],
    );
  }
}
