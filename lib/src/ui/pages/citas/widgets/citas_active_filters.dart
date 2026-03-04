import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/active_filter_chip.dart';

class CitasActiveFiltersRibbon extends StatelessWidget {
  final ThemeController theme;
  final String buscarTexto;
  final String? estadoFiltro;
  final String? medicoFiltroNombre;
  final DateTime? fechaInicioFiltro;
  final DateTime? fechaFinFiltro;
  final DateFormat formatter;
  final VoidCallback onClearBuscar;
  final VoidCallback onClearEstado;
  final VoidCallback onClearMedico;
  final VoidCallback onClearRango;
  final VoidCallback onClearAll;

  const CitasActiveFiltersRibbon({
    super.key,
    required this.theme,
    required this.buscarTexto,
    required this.estadoFiltro,
    required this.medicoFiltroNombre,
    required this.fechaInicioFiltro,
    required this.fechaFinFiltro,
    required this.formatter,
    required this.onClearBuscar,
    required this.onClearEstado,
    required this.onClearMedico,
    required this.onClearRango,
    required this.onClearAll,
  });

  bool get _hasActiveFilters {
    return buscarTexto.trim().isNotEmpty ||
        (estadoFiltro?.isNotEmpty ?? false) ||
        (medicoFiltroNombre?.isNotEmpty ?? false) ||
        fechaInicioFiltro != null ||
        fechaFinFiltro != null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActiveFilters) return const SizedBox.shrink();

    final chips = <Widget>[];
    if (buscarTexto.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: 'Buscar: ${buscarTexto.trim()}',
          onRemove: onClearBuscar,
        ),
      );
    }
    if (estadoFiltro?.isNotEmpty ?? false) {
      chips.add(
        ActiveFilterChip(label: 'Estado: $estadoFiltro', onRemove: onClearEstado),
      );
    }
    if (medicoFiltroNombre?.isNotEmpty ?? false) {
      chips.add(
        ActiveFilterChip(
          label: 'Médico: $medicoFiltroNombre',
          onRemove: onClearMedico,
        ),
      );
    }
    if (fechaInicioFiltro != null || fechaFinFiltro != null) {
      final inicio = fechaInicioFiltro != null
          ? formatter.format(fechaInicioFiltro!)
          : '--';
      final fin =
          fechaFinFiltro != null ? formatter.format(fechaFinFiltro!) : '--';
      chips.add(
        ActiveFilterChip(label: 'Rango: $inicio → $fin', onRemove: onClearRango),
      );
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
                  Icons.filter_alt_rounded,
                  size: 16,
                  color: theme.primary,
                ),
                const SizedBox(width: 8),
                Wrap(spacing: 8, children: chips),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onClearAll,
                  child: const Text('Limpiar filtros'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
