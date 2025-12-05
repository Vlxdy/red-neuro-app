import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class RoleTrayPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final List<String> actions;

  const RoleTrayPlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inbox_outlined, color: theme.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: theme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: theme.secondary),
          ),
          const SizedBox(height: 24),
          Text(
            'Acciones esperadas',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: theme.secondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: actions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.check_circle_outline, color: theme.primary),
                  title: Text(
                    actions[index],
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: theme.secondary),
                  ),
                  subtitle: const Text('Bandeja vacía (sin datos aún)'),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
