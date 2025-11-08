import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:flutter/material.dart';

class CustomTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final double? size;
  final double? fontSize;
  const CustomTitle({
    super.key,
    required this.title,
    this.icon,
    this.color,
    this.size,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                color: color ?? theme.primary,
                size: size ?? 28,
              ),
            if (icon != null) const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize ?? 22,
                fontWeight: FontWeight.bold,
                color: color ?? theme.primary,
              ),
            ),
          ],
        ));
  }
}
