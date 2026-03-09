import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class LoginDecorBackground extends StatelessWidget {
  const LoginDecorBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.primary.withValues(alpha: theme.isDark ? 0.34 : 0.22),
              theme.background,
              theme.accent500.withValues(alpha: theme.isDark ? 0.22 : 0.14),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            _LoginGlow(
              top: -90,
              left: -50,
              size: 270,
              color: theme.primary.withValues(alpha: theme.isDark ? 0.34 : 0.25),
            ),
            _LoginGlow(
              top: 140,
              right: -40,
              size: 220,
              color: theme.secondary.withValues(alpha: theme.isDark ? 0.22 : 0.18),
            ),
            _LoginGlow(
              bottom: -110,
              right: 20,
              size: 280,
              color: theme.accent500.withValues(alpha: theme.isDark ? 0.28 : 0.20),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginGlow extends StatelessWidget {
  const _LoginGlow({
    required this.size,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double size;
  final Color color;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
