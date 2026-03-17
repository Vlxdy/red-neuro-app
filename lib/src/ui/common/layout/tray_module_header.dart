import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/pages/notificaciones/notificaciones_page.dart';

class TrayModuleHeader extends StatefulWidget implements PreferredSizeWidget {
  final String titulo;
  final String subtitulo;
  final List<Widget> actions;
  final bool isCompact;
  final bool showNotificationsAction;

  const TrayModuleHeader({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.actions = const [],
    this.isCompact = false,
    this.showNotificationsAction = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(isCompact ? 58 : 54);

  @override
  State<TrayModuleHeader> createState() => _TrayModuleHeaderState();
}

class _TrayModuleHeaderState extends State<TrayModuleHeader> {

  void _showInfoDialog(BuildContext context) {
    if (widget.subtitulo.trim().isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(widget.titulo),
          content: Text(widget.subtitulo),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNotifications() async {
    if (!mounted) return;
    await abrirBandejaNotificaciones(context);
  }

  Widget _buildNotificationsAction(ThemeController theme) {
    return ValueListenableBuilder<int>(
      valueListenable: notificacionesNoLeidasNotifier,
      builder: (context, unreadCount, _) {
        return _HeaderActionButton(
          tooltip: 'Notificaciones',
          icon: Icons.notifications_none_rounded,
          onPressed: _openNotifications,
          theme: theme,
          badgeCount: unreadCount,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final Color headerBaseColor = theme.isDark ? theme.bgCard : theme.primary;
    final Color headerEndColor = theme.isDark ? theme.bgCard2 : theme.primary700;

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: headerBaseColor,
      surfaceTintColor: theme.transparent,
      titleSpacing: 16,
      toolbarHeight: widget.isCompact ? 52 : 48,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              headerBaseColor.withOpacity(theme.isDark ? 0.98 : 0.96),
              headerEndColor.withOpacity(theme.isDark ? 0.98 : 0.90),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: theme.white.withValues(alpha: theme.isDark ? 0.05 : 0.10),
            ),
          ),
        ),
      ),
      title: GestureDetector(
        onDoubleTap: () => _showInfoDialog(context),
        child: Text(
          widget.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: theme.white,
              ),
        ),
      ),
      actions: [
        if (widget.showNotificationsAction) ...[
          _buildNotificationsAction(theme),
          const SizedBox(width: 8),
        ],
        ...widget.actions,
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
    this.badgeCount = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final ThemeController theme;
  final int badgeCount;

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
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: TextStyle(
                      color: theme.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
