import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: theme.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: theme.grey),
          ),
        ],
      ),
    );
  }
}
