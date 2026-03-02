import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class CitasHeader extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool isCompact;
  final int currentViewIndex;
  final ValueChanged<int> onViewSelected;
  final VoidCallback onToggleFilters;
  final ThemeController theme;

  const CitasHeader({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.isCompact,
    required this.currentViewIndex,
    required this.onViewSelected,
    required this.onToggleFilters,
    required this.theme,
  });

  List<PopupMenuEntry<int>> _buildViewItems(TextStyle? textStyle) {
    const labels = ['Agenda diaria', 'Calendario', 'Listado'];
    return List.generate(
      labels.length,
      (index) => CheckedPopupMenuItem(
        value: index,
        checked: index == currentViewIndex,
        child: Text(labels[index], style: textStyle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = theme.white.withValues(alpha: 0.35);
    const iconSize = 18.0;
    const buttonSize = 32.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      decoration: BoxDecoration(color: theme.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.white,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: PopupMenuButton<int>(
                    tooltip: 'Vista',
                    padding: EdgeInsets.zero,
                    iconSize: iconSize,
                    onSelected: (value) {
                      if (value == currentViewIndex) return;
                      onViewSelected(value);
                    },
                    itemBuilder: (context) => _buildViewItems(
                      Theme.of(context).textTheme.bodySmall,
                    ),
                    icon: Icon(
                      Icons.view_list_rounded,
                      color: theme.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onToggleFilters,
                icon: Icon(
                  Icons.filter_list_rounded,
                  size: iconSize,
                  color: theme.white,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(buttonSize, buttonSize),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: borderColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 420,
                child: Text(
                  subtitulo,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: theme.white),
                ),
              ),
              if (!isCompact)
                Text(
                  'Agenda médica',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: theme.white),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
