import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:flutter/material.dart';

class EstadoFilterChips extends StatefulWidget {
  const EstadoFilterChips({
    super.key,
    required this.estadosSeleccionados,
    required this.onToggle,
    this.onClear,
  });

  final Set<CitasEstado> estadosSeleccionados;
  final ValueChanged<CitasEstado> onToggle;
  final VoidCallback? onClear;

  @override
  State<EstadoFilterChips> createState() => _EstadoFilterChipsState();
}

class _EstadoFilterChipsState extends State<EstadoFilterChips> {
  final ThemeController theme = ThemeController.instance;
  late bool _expandido;

  @override
  void initState() {
    super.initState();
    _expandido = widget.estadosSeleccionados.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant EstadoFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estadosSeleccionados.isNotEmpty && !_expandido) {
      _expandido = true;
    }
  }

  String get _resumenEstados {
    if (widget.estadosSeleccionados.isEmpty) {
      return 'Filtrar por estado';
    }
    if (widget.estadosSeleccionados.length == CitasEstado.values.length) {
      return 'Todos los estados seleccionados';
    }
    return widget.estadosSeleccionados
        .map((estado) => estado.label)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _expandido = !_expandido;
            });
          },
          icon: Icon(
            _expandido ? Icons.filter_alt_off_outlined : Icons.filter_alt_outlined,
          ),
          label: SizedBox(
            width: double.infinity,
            child: Text(
              _resumenEstados,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _expandido ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: CitasEstado.values.map((estado) {
                  final seleccionado =
                      widget.estadosSeleccionados.contains(estado);
                  final color = estado.color(theme);
                  final textColor = estado.textColor(theme);
                  return FilterChip(
                    label: Text(
                      estado.label,
                      style: TextStyle(
                        color: seleccionado ? textColor : theme.fontColor,
                        fontWeight:
                            seleccionado ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    backgroundColor: theme.monochromatic200,
                    selectedColor: color.withOpacity(theme.isLight ? 0.85 : 0.6),
                    selected: seleccionado,
                    onSelected: (_) => widget.onToggle(estado),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: seleccionado ? color : theme.monochromatic500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (widget.onClear != null &&
                  widget.estadosSeleccionados.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: widget.onClear,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar filtros de estado'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
