import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/models/cita.dart';

class CitasConfirmarSolicitadaResult {
  const CitasConfirmarSolicitadaResult({
    required this.detalle,
    required this.fechaInicio,
  });

  final String detalle;
  final DateTime? fechaInicio;

  Map<String, dynamic> toRequestBody(CitaMedica cita) {
    final body = <String, dynamic>{};
    final detalleActual = cita.detalle.trim();
    final detalleNuevo = detalle.trim();
    if (detalleNuevo != detalleActual) {
      body['detalle'] = detalleNuevo;
    }
    if (fechaInicio != null && fechaInicio != cita.fechaInicio) {
      body['fechaInicio'] = fechaInicio!.toUtc().toIso8601String();
    }
    return body;
  }
}

Future<CitasConfirmarSolicitadaResult?> showCitasConfirmarSolicitadaDialog({
  required BuildContext context,
  required CitaMedica cita,
  required DateFormat dateTimeFormat,
  String title = 'Confirmar cita solicitada',
}) async {
  return showDialog<CitasConfirmarSolicitadaResult>(
    context: context,
    builder: (_) => _CitasConfirmarSolicitadaDialog(
      cita: cita,
      dateTimeFormat: dateTimeFormat,
      title: title,
    ),
  );
}

class _CitasConfirmarSolicitadaDialog extends StatefulWidget {
  const _CitasConfirmarSolicitadaDialog({
    required this.cita,
    required this.dateTimeFormat,
    required this.title,
  });

  final CitaMedica cita;
  final DateFormat dateTimeFormat;
  final String title;

  @override
  State<_CitasConfirmarSolicitadaDialog> createState() =>
      _CitasConfirmarSolicitadaDialogState();
}

class _CitasConfirmarSolicitadaDialogState
    extends State<_CitasConfirmarSolicitadaDialog> {
  late final TextEditingController _detalleController;
  DateTime? _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _detalleController = TextEditingController(text: widget.cita.detalle);
    _fechaSeleccionada = widget.cita.fechaInicio;
  }

  @override
  void dispose() {
    _detalleController.dispose();
    super.dispose();
  }

  Future<DateTime?> _seleccionarFechaHora(DateTime? base) async {
    final now = DateTime.now();
    final fechaBase = base ?? now;

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaBase,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (fecha == null) return null;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(fechaBase),
    );
    if (hora == null) return null;

    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.top - keyboardInset - 32;
    final dialogHeight = availableHeight.clamp(260.0, 560.0);
    final dialogAlignment =
        keyboardInset > 0 ? Alignment.topCenter : Alignment.center;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardInset > 0 ? 16 : 24),
      child: Align(
        alignment: dialogAlignment,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Dialog(
              insetPadding: EdgeInsets.zero,
              child: SizedBox(
                height: dialogHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Antes de confirmar, revisa el comentario y la fecha para que el flujo sea claro para el paciente.',
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _detalleController,
                                minLines: 3,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  labelText: 'Comentario',
                                  hintText:
                                      'Agrega o ajusta el comentario de la cita',
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final nuevaFecha = await _seleccionarFechaHora(
                                      _fechaSeleccionada,
                                    );
                                    if (nuevaFecha == null || !mounted) return;
                                    setState(() => _fechaSeleccionada = nuevaFecha);
                                  },
                                  icon: const Icon(Icons.schedule),
                                  label: Text(
                                    _fechaSeleccionada == null
                                        ? 'Seleccionar fecha y hora'
                                        : 'Fecha y hora: ${widget.dateTimeFormat.format(_fechaSeleccionada!)}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        spacing: 12,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                CitasConfirmarSolicitadaResult(
                                  detalle: _detalleController.text.trim(),
                                  fechaInicio: _fechaSeleccionada,
                                ),
                              );
                            },
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
