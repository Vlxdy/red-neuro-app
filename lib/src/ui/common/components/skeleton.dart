import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class SkeletonGrid extends StatelessWidget {
  final int rows;
  final int columns;
  final double itemHeight;
  final double itemWidth;
  final bool isCircular;

  const SkeletonGrid({
    super.key,
    required this.rows,
    required this.columns,
    this.itemHeight = 100,
    this.itemWidth = 100,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      physics:
          const NeverScrollableScrollPhysics(), // Evita scroll en el skeleton
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: itemWidth / itemHeight,
      ),
      itemCount: rows * columns,
      itemBuilder: (context, index) {
        return _buildSkeletonItem(context);
      },
    );
  }

  Widget _buildSkeletonItem(BuildContext context) {
    final theme = ThemeController.instance;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.monochromatic200, // Color de carga
        borderRadius: BorderRadius.circular(isCircular ? itemWidth / 2 : 10),
      ),
    );
  }
}
