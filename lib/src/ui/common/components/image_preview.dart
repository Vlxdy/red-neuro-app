import 'dart:io';
import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class ImagePreviewDialog extends StatelessWidget {
  final String imagePath;

  const ImagePreviewDialog({required this.imagePath, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Dialog(
      backgroundColor: theme.transparent,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: theme.black,
              ),
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: theme.black.withValues(alpha: 0.54),
              onPressed: () => Navigator.of(context).pop(),
              child: Icon(Icons.close, color: theme.white),
            ),
          ),
        ],
      ),
    );
  }
}
