import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class CitasDetalleSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final ThemeController theme;

  const CitasDetalleSection({
    super.key,
    required this.title,
    required this.children,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: theme.grey,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class CitasDetalleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeController theme;

  const CitasDetalleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedValue = value.trim().isNotEmpty ? value : '--';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: theme.grey,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  resolvedValue,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
