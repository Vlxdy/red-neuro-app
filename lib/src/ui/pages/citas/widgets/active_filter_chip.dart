import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class ActiveFilterChip extends StatelessWidget {
  final String label;

  const ActiveFilterChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
