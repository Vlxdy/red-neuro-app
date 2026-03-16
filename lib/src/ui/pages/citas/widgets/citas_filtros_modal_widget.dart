import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_filters_fields.dart';

class CitasFiltrosModalWidget extends StatelessWidget {
  final ScrollController filtersScrollController;
  final TextEditingController buscarController;
  final ValueChanged<String> onBuscarChanged;
  final TextEditingController estadoController;
  final Future<void> Function() onTapEstado;
  final bool mostrarFiltroMedico;
  final TextEditingController personalAsignadoController;
  final String? personalAsignadoIdSeleccionado;
  final bool bloquearFiltroPersonalAsignado;
  final String? etiquetaPersonalAsignadoBloqueado;
  final Future<void> Function() onTapPersonalAsignado;
  final VoidCallback onClearPersonalAsignado;
  final TextEditingController lugarController;
  final String? lugarIdSeleccionado;
  final Future<void> Function() onTapLugar;
  final VoidCallback onClearLugar;
  final VoidCallback onLimpiar;
  final VoidCallback onAplicar;

  const CitasFiltrosModalWidget({
    super.key,
    required this.filtersScrollController,
    required this.buscarController,
    required this.onBuscarChanged,
    required this.estadoController,
    required this.onTapEstado,
    required this.mostrarFiltroMedico,
    required this.personalAsignadoController,
    required this.personalAsignadoIdSeleccionado,
    required this.bloquearFiltroPersonalAsignado,
    this.etiquetaPersonalAsignadoBloqueado,
    required this.onTapPersonalAsignado,
    required this.onClearPersonalAsignado,
    required this.lugarController,
    required this.lugarIdSeleccionado,
    required this.onTapLugar,
    required this.onClearLugar,
    required this.onLimpiar,
    required this.onAplicar,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Filtros',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                      ),
                      child: Scrollbar(
                        controller: filtersScrollController,
                        child: SingleChildScrollView(
                          controller: filtersScrollController,
                          child: CitasFiltersFields(
                            isCompact: true,
                            buscarController: buscarController,
                            onBuscarChanged: (value) {
                              onBuscarChanged(value);
                              setStateModal(() {});
                            },
                            estadoController: estadoController,
                            onTapEstado: () async {
                              await onTapEstado();
                              setStateModal(() {});
                            },
                            mostrarFiltroMedico: mostrarFiltroMedico,
                            personalAsignadoController:
                                personalAsignadoController,
                            personalAsignadoIdSeleccionado:
                                personalAsignadoIdSeleccionado,
                            bloquearFiltroPersonalAsignado:
                                bloquearFiltroPersonalAsignado,
                            etiquetaPersonalAsignadoBloqueado:
                                etiquetaPersonalAsignadoBloqueado,
                            onTapPersonalAsignado: () async {
                              await onTapPersonalAsignado();
                              setStateModal(() {});
                            },
                            onClearPersonalAsignado: () {
                              onClearPersonalAsignado();
                              setStateModal(() {});
                            },
                            lugarController: lugarController,
                            lugarIdSeleccionado: lugarIdSeleccionado,
                            onTapLugar: () async {
                              await onTapLugar();
                              setStateModal(() {});
                            },
                            onClearLugar: () {
                              onClearLugar();
                              setStateModal(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              onLimpiar();
                              setStateModal(() {});
                            },
                            child: const Text('Limpiar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: onAplicar,
                            icon: const Icon(Icons.sync),
                            label: const Text('Aplicar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
