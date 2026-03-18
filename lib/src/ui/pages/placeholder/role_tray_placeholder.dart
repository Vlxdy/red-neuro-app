import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class RoleTrayPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final List<String> actions;
  final IconData? leadingIcon;

  const RoleTrayPlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.actions,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.primary.withValues(alpha: theme.isLight ? 0.12 : 0.2),
              theme.bgCard,
            ],
          ),
          border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.black.withValues(alpha: theme.isLight ? 0.05 : 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                leadingIcon ?? Icons.inbox_outlined,
                color: theme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: theme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.fontColor.withValues(alpha: 0.78),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Qué puedes hacer aquí',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: theme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: actions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.bgCard2.withValues(
                        alpha: theme.isLight ? 0.7 : 0.22,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.grey.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: theme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                actions[index],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: theme.fontColor,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bandeja lista para mostrar contenido cuando haya datos.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: theme.fontColor.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
