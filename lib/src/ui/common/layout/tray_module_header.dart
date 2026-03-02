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
  Size get preferredSize => Size.fromHeight(isCompact ? 68 : 62);

  Widget _buildInfoAction(BuildContext context, ThemeController theme) {
    return IconButton(
      tooltip: 'Información de esta bandeja',
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
      icon: Icon(Icons.info_outline_rounded, color: theme.white),
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        side: BorderSide(color: theme.white.withValues(alpha: 0.35)),
      ),
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
      titleSpacing: 20,
      toolbarHeight: isCompact ? 62 : 58,
      title: Text(
        titulo,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.white,
        ),
      ),
      actions: [_buildInfoAction(context, theme), ...actions, const SizedBox(width: 12)],
    );
  }
}
