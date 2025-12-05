import 'package:flutter/material.dart';

class CustomSimpleCircle extends StatelessWidget {
  final double customRadius;
  final Color? customColor;
  const CustomSimpleCircle({
    this.customColor,
    this.customRadius = 100.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: customRadius,
      height: customRadius,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(customRadius),
        // color: Color.fromRGBO(255, 255, 255, 0.05)),
        color:
            customColor?.withValues(alpha: 0.1) ??
            const Color.fromRGBO(255, 255, 255, 0.05),
      ),
    );
  }
}
