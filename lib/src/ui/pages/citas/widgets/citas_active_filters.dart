import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/active_filter_chip.dart';

class CitasActiveFiltersRibbon extends StatelessWidget {
  final ThemeController theme;
  final String buscarTexto;
  final String? estadoFiltro;
  final String? medicoFiltro;
  final DateTime? fechaInicioFiltro;
  final DateTime? fechaFinFiltro;
  final DateFormat formatter;

  const CitasActiveFiltersRibbon({
    super.key,
    required this.theme,
    required this.buscarTexto,
    required this.estadoFiltro,
    required this.medicoFiltro,
    required this.fechaInicioFiltro,
    required this.fechaFinFiltro,
    required this.formatter,
  });

  bool get _hasActiveFilters {
    return buscarTexto.trim().isNotEmpty ||
        (estadoFiltro?.isNotEmpty ?? false) ||
        (medicoFiltro?.isNotEmpty ?? false) ||
        fechaInicioFiltro != null ||
        fechaFinFiltro != null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActiveFilters) return const SizedBox.shrink();

    final chips = <Widget>[];
    if (buscarTexto.trim().isNotEmpty) {
      chips.add(ActiveFilterChip(label: 'Buscar: ${buscarTexto.trim()}'));
    }
    if (estadoFiltro?.isNotEmpty ?? false) {
      chips.add(ActiveFilterChip(label: 'Estado: $estadoFiltro'));
    }
    if (medicoFiltro?.isNotEmpty ?? false) {
      chips.add(ActiveFilterChip(label: 'Médico: $medicoFiltro'));
    }
    if (fechaInicioFiltro != null || fechaFinFiltro != null) {
      final inicio = fechaInicioFiltro != null
          ? formatter.format(fechaInicioFiltro!)
          : '--';
      final fin =
          fechaFinFiltro != null ? formatter.format(fechaFinFiltro!) : '--';
      chips.add(ActiveFilterChip(label: 'Rango: $inicio → $fin'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.funnel,
                  size: 16,
                  color: theme.primary,
                ),
                const SizedBox(width: 8),
                Wrap(spacing: 8, children: chips),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
