import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/ui/pages/citas_medicas/services/citas_medicas_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CitaFormSheet extends StatefulWidget {
  const CitaFormSheet({
    super.key,
    required this.service,
    this.cita,
  });

  final CitasMedicasService service;
  final Cita? cita;

  @override
  State<CitaFormSheet> createState() => _CitaFormSheetState();
}

class _CitaFormSheetState extends State<CitaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _detalleController = TextEditingController();
  final _theme = ThemeController.instance;

  DateTime? _fecha;
  TimeOfDay? _horaInicio;
  DateTime? _fechaHoraFin; // se calcula automáticamente
  bool _guardando = false;
  String? _errorTemporal;
  final DateFormat _fechaLarga = DateFormat("EEEE d 'de' MMMM yyyy", 'es');
  final DateFormat _horaCorta = DateFormat('HH:mm', 'es');

  @override
  void initState() {
    super.initState();
    final cita = widget.cita;
    if (cita != null) {
      _detalleController.text = cita.detalle;
      _fecha = DateTime(
          cita.fechaInicio.year, cita.fechaInicio.month, cita.fechaInicio.day);
      _horaInicio = TimeOfDay.fromDateTime(cita.fechaInicio);
      _fechaHoraFin = cita.fechaFin;
    }
  }

  @override
  void dispose() {
    _detalleController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final base = _fecha ?? DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (seleccion != null) {
      setState(() {
        _fecha = DateUtils.dateOnly(seleccion);
        _recalcularFin();
      });
    }
  }

  Future<void> _seleccionarHoraInicio() async {
    final seleccion = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
    );
    if (seleccion != null) {
      setState(() {
        _horaInicio = seleccion;
        _recalcularFin();
      });
    }
  }

  void _recalcularFin() {
    if (_fecha != null && _horaInicio != null) {
      final inicio = DateTime(_fecha!.year, _fecha!.month, _fecha!.day,
          _horaInicio!.hour, _horaInicio!.minute);
      _fechaHoraFin = inicio.add(const Duration(hours: 1));
    } else {
      _fechaHoraFin = null;
    }
  }

  String? _validarDetalle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Describe brevemente el motivo de la cita';
    }
    if (value.trim().length < 10) {
      return 'El detalle debe tener al menos 10 caracteres';
    }
    return null;
  }

  String? _validarCamposTemporales() {
    if (_fecha == null) return 'Selecciona la fecha de la cita';
    if (_horaInicio == null) return 'Selecciona la hora de inicio';
    final inicio = _combinarFechaHora(_horaInicio!);
    final fin = _fechaHoraFin;
    if (inicio == null || fin == null) {
      return 'No fue posible construir el horario de la cita';
    }
    if (inicio.isBefore(DateTime.now())) {
      return 'Selecciona un horario posterior al actual';
    }
    return null;
  }

  DateTime? _combinarFechaHora(TimeOfDay hora) {
    final fecha = _fecha ?? DateTime.now();
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    final detalleValido = _formKey.currentState?.validate() ?? false;
    final errorTemporal = _validarCamposTemporales();

    setState(() {
      _errorTemporal = errorTemporal;
    });

    if (!detalleValido || errorTemporal != null) {
      return;
    }

    final inicio = _combinarFechaHora(_horaInicio!);
    final fin = _fechaHoraFin;
    if (inicio == null || fin == null) return;

    setState(() {
      _guardando = true;
    });

    final detalle = _detalleController.text.trim();
    bool exito = false;

    if (widget.cita == null) {
      exito = await widget.service.crearCitaPaciente(
        fechaInicio: inicio,
        fechaFin: fin,
        detalle: detalle,
      );
    } else {
      exito = await widget.service.actualizarCitaPaciente(
        cita: widget.cita!,
        fechaInicio: inicio,
        fechaFin: fin,
        detalle: detalle,
      );
    }

    if (!mounted) return;

    setState(() {
      _guardando = false;
    });

    if (exito) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.cita != null;
    final fechaInicioFormateada = _fecha != null && _horaInicio != null
        ? '${_fechaLarga.format(_fecha!)} • ${_horaInicio!.format(context)}'
        : null;

    final fechaFinFormateada =
        _fechaHoraFin != null ? _horaCorta.format(_fechaHoraFin!) : null;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: _theme.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          esEdicion
                              ? 'Editar cita médica'
                              : 'Nueva cita médica',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _detalleController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Detalle de la cita',
                      alignLabelWithHint: true,
                    ),
                    validator: _validarDetalle,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _seleccionarFecha,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _fecha == null
                          ? 'Seleccionar fecha'
                          : _fechaLarga.format(_fecha!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _seleccionarHoraInicio,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(
                      _horaInicio == null
                          ? 'Seleccionar hora de inicio'
                          : 'Hora de inicio: ${_horaInicio!.format(context)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_errorTemporal != null)
                    Text(
                      _errorTemporal!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_fecha != null &&
                      _horaInicio != null &&
                      _fechaHoraFin != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'La cita será el $fechaInicioFormateada '
                              'hasta las $fechaFinFormateada',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _theme.white,
                              ),
                            )
                          : Icon(
                              esEdicion
                                  ? Icons.save_outlined
                                  : Icons.add_circle_outline,
                              color: _theme.white,
                            ),
                      label: Text(
                        esEdicion ? 'Guardar cambios' : 'Crear cita',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _theme.primary,
                        foregroundColor: _theme.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
