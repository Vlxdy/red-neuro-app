import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';

class CitasFiltersFields extends StatelessWidget {
  final bool isCompact;
  final TextEditingController buscarController;
  final ValueChanged<String> onBuscarChanged;
  final TextEditingController estadoController;
  final VoidCallback onTapEstado;
  final bool mostrarFiltroMedico;
  final TextEditingController personalAsignadoController;
  final VoidCallback onTapPersonalAsignado;
  final VoidCallback onClearPersonalAsignado;
  final String? personalAsignadoIdSeleccionado;
  final TextEditingController lugarController;
  final VoidCallback onTapLugar;
  final VoidCallback onClearLugar;
  final String? lugarIdSeleccionado;
  final bool bloquearFiltroPersonalAsignado;
  final String? etiquetaPersonalAsignadoBloqueado;

  const CitasFiltersFields({
    super.key,
    required this.isCompact,
    required this.buscarController,
    required this.onBuscarChanged,
    required this.estadoController,
    required this.onTapEstado,
    required this.mostrarFiltroMedico,
    required this.personalAsignadoController,
    required this.onTapPersonalAsignado,
    required this.onClearPersonalAsignado,
    required this.personalAsignadoIdSeleccionado,
    required this.lugarController,
    required this.onTapLugar,
    required this.onClearLugar,
    required this.lugarIdSeleccionado,
    this.bloquearFiltroPersonalAsignado = false,
    this.etiquetaPersonalAsignadoBloqueado,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        SizedBox(
          width: isCompact ? double.infinity : 180,
          child: CustomTextInput(
            title: 'Buscar',
            controller: buscarController,
            onChange: onBuscarChanged,
          ),
        ),
        SizedBox(
          width: isCompact ? double.infinity : 160,
          child: TextFormField(
            readOnly: true,
            controller: estadoController,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.expand_more),
            ),
            onTap: onTapEstado,
          ),
        ),
        if (mostrarFiltroMedico)
          SizedBox(
            width: isCompact ? double.infinity : 160,
            child: TextFormField(
              controller: personalAsignadoController,
              readOnly: true,
              enabled: !bloquearFiltroPersonalAsignado,
              decoration: InputDecoration(
                labelText: 'Personal asignado',
                hintText: bloquearFiltroPersonalAsignado
                    ? (etiquetaPersonalAsignadoBloqueado?.trim().isNotEmpty ??
                              false)
                          ? etiquetaPersonalAsignadoBloqueado
                          : 'Solo mis citas'
                    : 'Selecciona personal asignado',
                helperText: bloquearFiltroPersonalAsignado
                    ? 'Modo activo: solo mis citas'
                    : null,
                border: const OutlineInputBorder(),
                suffixIcon: bloquearFiltroPersonalAsignado
                    ? const Icon(Icons.lock_rounded)
                    : personalAsignadoIdSeleccionado == null
                    ? const Icon(Icons.expand_more)
                    : IconButton(
                        tooltip: 'Quitar',
                        icon: const Icon(Icons.close),
                        onPressed: onClearPersonalAsignado,
                      ),
              ),
              onTap: bloquearFiltroPersonalAsignado
                  ? null
                  : onTapPersonalAsignado,
            ),
          ),
        SizedBox(
          width: isCompact ? double.infinity : 160,
          child: TextFormField(
            controller: lugarController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Lugar',
              hintText: 'Selecciona un lugar',
              border: const OutlineInputBorder(),
              suffixIcon: lugarIdSeleccionado == null
                  ? const Icon(Icons.expand_more)
                  : IconButton(
                      tooltip: 'Quitar',
                      icon: const Icon(Icons.close),
                      onPressed: onClearLugar,
                    ),
            ),
            onTap: onTapLugar,
          ),
        ),
      ],
    );
  }
}
