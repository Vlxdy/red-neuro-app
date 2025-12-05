import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:flutter/material.dart';

class CounterBadge extends StatelessWidget {
  const CounterBadge({
    super.key,
    required this.child,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.maxCount = 99,
    this.offset = const Offset(-6, -6),
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.minSize = 18,
    this.showZero = false,
    this.borderColor,
  });

  final Widget child;
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final int maxCount;
  final Offset offset;
  final EdgeInsetsGeometry padding;
  final double minSize;
  final bool showZero;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (!showZero && count <= 0) {
      return child;
    }

    final theme = ThemeController.instance;
    final display = count > maxCount ? '$maxCount+' : count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: offset.dx,
          top: offset.dy,
          child: Container(
            padding: padding,
            constraints: BoxConstraints(minHeight: minSize, minWidth: minSize),
            decoration: BoxDecoration(
              color: backgroundColor ?? theme.error,
              borderRadius: BorderRadius.circular(minSize),
              border: Border.all(color: borderColor ?? theme.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                display,
                style: TextStyle(
                  color: textColor ?? theme.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
