import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.grey),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: theme.grey),
        ),
      ],
    );
  }
}
