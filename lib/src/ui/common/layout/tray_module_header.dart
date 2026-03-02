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
  Size get preferredSize => Size.fromHeight(isCompact ? 104 : 92);

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
      actions: [...actions, const SizedBox(width: 12)],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(isCompact ? 42 : 34),
        child: Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            subtitulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
