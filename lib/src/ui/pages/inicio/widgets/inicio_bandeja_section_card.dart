import 'package:flutter/material.dart';

class InicioBandejaSectionCard extends StatelessWidget {
  const InicioBandejaSectionCard({
    super.key,
    required this.titulo,
    required this.total,
    required this.isCollapsed,
    required this.onToggle,
    required this.content,
    this.onViewAll,
  });

  final String titulo;
  final int total;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final List<Widget> content;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleColor = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isCollapsed && total > 0) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: subtleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$total',
                        style: TextStyle(
                          fontSize: 10,
                          color: subtleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
                  ],
                ),
              ),
            ),
            if (!isCollapsed) ...[
              const SizedBox(height: 8),
              ...content,
              if (onViewAll != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onViewAll,
                    icon: const Icon(Icons.chevron_right),
                    label: Text('Ver todas ($total)'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
