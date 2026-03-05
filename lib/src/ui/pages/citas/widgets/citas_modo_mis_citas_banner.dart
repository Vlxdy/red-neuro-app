import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class CitasModoMisCitasBanner extends StatelessWidget {
  final bool visible;
  final String nombreMedicoActual;

  const CitasModoMisCitasBanner({
    super.key,
    required this.visible,
    required this.nombreMedicoActual,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final theme = ThemeController.instance;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary.withValues(alpha: 0.18),
            theme.secondary.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_pin_circle_rounded, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mostrando solo citas asignadas a ti',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
