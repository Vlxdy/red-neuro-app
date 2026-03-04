import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/filtro_fecha.dart';

class CitasFiltersFields extends StatelessWidget {
  final bool isCompact;
  final TextEditingController buscarController;
  final ValueChanged<String> onBuscarChanged;
  final String? estadoFiltro;
  final ValueChanged<String?> onEstadoChanged;
  final bool mostrarFiltroMedico;
  final TextEditingController medicoController;
  final VoidCallback onTapMedico;
  final VoidCallback onClearMedico;
  final String? medicoIdSeleccionado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateFormat formatter;
  final VoidCallback onTapFechaInicio;
  final VoidCallback onTapFechaFin;
  final bool bloquearFiltroMedico;
  final String? etiquetaMedicoBloqueado;

  const CitasFiltersFields({
    super.key,
    required this.isCompact,
    required this.buscarController,
    required this.onBuscarChanged,
    required this.estadoFiltro,
    required this.onEstadoChanged,
    required this.mostrarFiltroMedico,
    required this.medicoController,
    required this.onTapMedico,
    required this.onClearMedico,
    required this.medicoIdSeleccionado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.formatter,
    required this.onTapFechaInicio,
    required this.onTapFechaFin,
    this.bloquearFiltroMedico = false,
    this.etiquetaMedicoBloqueado,
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
          child: DropdownButtonFormField<String?>(
            initialValue: estadoFiltro,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...CitaEstado.values.map(
                (estado) => DropdownMenuItem(value: estado, child: Text(estado)),
              ),
            ],
            onChanged: onEstadoChanged,
          ),
        ),
        if (mostrarFiltroMedico)
          SizedBox(
            width: isCompact ? double.infinity : 160,
            child: TextFormField(
              controller: medicoController,
              readOnly: true,
              enabled: !bloquearFiltroMedico,
              decoration: InputDecoration(
                labelText: 'Médico',
                hintText: bloquearFiltroMedico
                    ? (etiquetaMedicoBloqueado?.trim().isNotEmpty ?? false)
                          ? etiquetaMedicoBloqueado
                          : 'Filtrando por ti'
                    : 'Selecciona un médico',
                helperText: bloquearFiltroMedico
                    ? 'Filtro bloqueado mientras usas "Solo mis citas"'
                    : null,
                border: const OutlineInputBorder(),
                suffixIcon: bloquearFiltroMedico
                    ? const Icon(Icons.lock_rounded)
                    : medicoIdSeleccionado == null
                    ? const Icon(Icons.expand_more)
                    : IconButton(
                        tooltip: 'Quitar',
                        icon: const Icon(Icons.close),
                        onPressed: onClearMedico,
                      ),
              ),
              onTap: bloquearFiltroMedico ? null : onTapMedico,
            ),
          ),
        FiltroFecha(
          label: 'Desde',
          value: fechaInicio,
          formatter: formatter,
          onTap: onTapFechaInicio,
        ),
        FiltroFecha(
          label: 'Hasta',
          value: fechaFin,
          formatter: formatter,
          onTap: onTapFechaFin,
        ),
      ],
    );
  }
}
