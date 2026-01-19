import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class CitasHeader extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool isCompact;
  final ThemeController theme;

  const CitasHeader({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.isCompact,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: isCompact ? double.infinity : 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
                    ),
              ),
              Text(
                subtitulo,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (!isCompact)
          Text('Agenda médica', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
