import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class TrayStatusBadge extends StatelessWidget {
  const TrayStatusBadge({
    required this.status,
    super.key,
    this.activeColor,
  });

  final String status;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    final isActive = normalized == 'ACTIVO';
    final okColor = activeColor ?? Colors.green.shade700;
    final color = isActive ? okColor : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle_filled,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            normalized,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class TrayAdminBadge extends StatelessWidget {
  const TrayAdminBadge({super.key, this.label = 'Cuenta administradora'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.primary.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 15, color: theme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: theme.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class CopyableInfoPill extends StatelessWidget {
  const CopyableInfoPill({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
    this.onTap,
    this.copied = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.primary),
              const SizedBox(width: 6),
              Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(value),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 14,
                  color: theme.primary,
                ),
                if (copied)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Copiado',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void showCopiedMessage(
  GlobalKey<ScaffoldMessengerState> messenger,
  String field,
) {
  final state = messenger.currentState;
  if (state == null) return;
  state
    ..hideCurrentSnackBar()
    ..clearMaterialBanners()
    ..showMaterialBanner(
      MaterialBanner(
        content: Text('Se copió el $field.'),
        leading: const Icon(Icons.check_circle_outline),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => state.hideCurrentMaterialBanner(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
}
