import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class TrayModuleHeader extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final String subtitulo;
  final List<Widget> actions;
  final bool isCompact;

  const TrayModuleHeader({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.actions = const [],
    this.isCompact = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(isCompact ? 58 : 54);

  Widget _buildInfoAction(BuildContext context, ThemeController theme) {
    return _HeaderActionButton(
      tooltip: 'Información de esta bandeja',
      icon: Icons.info_outline_rounded,
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(titulo),
              content: Text(subtitulo),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            );
          },
        );
      },
      theme: theme,
    );
  }

  Widget _buildNotificationsAction(ThemeController theme) {
    return _HeaderActionButton(
      tooltip: 'Notificaciones (próximamente)',
      icon: Icons.notifications_none_rounded,
      onPressed: null,
      theme: theme,
      showComingSoonDot: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.primary,
      surfaceTintColor: theme.transparent,
      titleSpacing: 16,
      toolbarHeight: isCompact ? 52 : 48,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.primary.withOpacity(theme.isDark ? 0.90 : 0.96),
              theme.primary700.withOpacity(theme.isDark ? 0.84 : 0.90),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: theme.white.withValues(alpha: theme.isDark ? 0.05 : 0.10),
            ),
          ),
        ),
      ),
      title: Text(
        titulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: theme.white,
        ),
      ),
      actions: [
        _buildNotificationsAction(theme),
        const SizedBox(width: 8),
        _buildInfoAction(context, theme),
        ...actions,
        const SizedBox(width: 12),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.theme,
    this.showComingSoonDot = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final ThemeController theme;
  final bool showComingSoonDot;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 20,
              color: isEnabled
                  ? theme.white
                  : theme.white.withValues(alpha: 0.72),
            ),
            style: IconButton.styleFrom(
              minimumSize: const Size(34, 34),
              fixedSize: const Size(34, 34),
              padding: EdgeInsets.zero,
              backgroundColor: theme.white.withValues(
                alpha: isEnabled ? 0.10 : 0.07,
              ),
              side: BorderSide(
                color: theme.white.withValues(alpha: isEnabled ? 0.28 : 0.16),
              ),
            ),
          ),
          if (showComingSoonDot)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: theme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
