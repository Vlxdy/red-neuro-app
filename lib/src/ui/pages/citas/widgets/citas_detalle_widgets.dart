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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        decoration: BoxDecoration(
          color: theme.bgCard2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: theme.grey,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
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

class CitasHistorialTimelineItem extends StatelessWidget {
  final String fecha;
  final String titulo;
  final String subtitulo;
  final List<String> detalles;
  final ThemeController theme;
  final bool isLast;

  const CitasHistorialTimelineItem({
    super.key,
    required this.fecha,
    required this.titulo,
    required this.subtitulo,
    required this.detalles,
    required this.theme,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final hasDetalles = detalles.isNotEmpty;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Stack(
              children: [
                if (!isLast)
                  Positioned(
                    left: 9,
                    top: 14,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: theme.grey.withValues(alpha: 0.3),
                    ),
                  ),
                Positioned(
                  left: 4,
                  top: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fecha,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: theme.grey,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.bgCard2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.grey.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (subtitulo.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subtitulo,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: theme.primary),
                            ),
                          ),
                        ],
                        if (hasDetalles) ...[
                          const SizedBox(height: 8),
                          ...detalles.map(
                            (detalle) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: theme.grey.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      detalle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CitasDetalleGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minItemWidth;
  final int? columns;

  const CitasDetalleGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 0,
    this.minItemWidth = 230,
    this.columns,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (columns != null && columns! > 1) {
          final requested = columns!;
          final requestedWidth =
              (constraints.maxWidth - (spacing * (requested - 1))) / requested;
          if (requestedWidth >= minItemWidth) {
            return Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              children: [
                for (final child in children)
                  SizedBox(
                    width: requestedWidth,
                    child: child,
                  ),
              ],
            );
          }
        }

        final canUseTwoColumns = constraints.maxWidth >=
            (minItemWidth * 2) + spacing;
        final itemWidth = canUseTwoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
