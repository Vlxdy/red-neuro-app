import 'dart:ui';

import 'package:flutter/material.dart';

class CustomCircle extends StatelessWidget {
  final double customRadius;
  final Color? customColor;
  const CustomCircle({this.customColor, this.customRadius = 100.0, super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0),
      child: Container(
        width: customRadius,
        height: customRadius,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(customRadius),
          // color: Color.fromRGBO(255, 255, 255, 0.05)),
          color:
              customColor?.withValues(alpha: 0.1) ??
              const Color.fromRGBO(255, 255, 255, 0.05),
        ),
      ),
    );
  }
}
