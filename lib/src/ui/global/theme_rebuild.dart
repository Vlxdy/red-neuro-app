import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class ThemeRebuild extends StatelessWidget {
  final Widget child;

  const ThemeRebuild({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.brightness,
      builder: (BuildContext context, bool _, Widget? _) {
        return KeyedSubtree(
          key: ValueKey(ThemeController.instance.isLight),
          child: child,
        );
      },
    );
  }
}
