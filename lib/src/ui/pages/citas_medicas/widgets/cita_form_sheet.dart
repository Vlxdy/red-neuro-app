import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/models/cita.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/services/citas_medicas_service.dart';
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
  TimeOfDay? _horaFin;
  bool _guardando = false;
  final DateFormat _fechaLarga = DateFormat("EEEE d 'de' MMMM yyyy", 'es');

  @override
  void initState() {
    super.initState();
    final cita = widget.cita;
    if (cita != null) {
      _detalleController.text = cita.detalle;
      _fecha = DateTime(cita.fechaInicio.year, cita.fechaInicio.month, cita.fechaInicio.day);
      _horaInicio = TimeOfDay.fromDateTime(cita.fechaInicio);
      _horaFin = TimeOfDay.fromDateTime(cita.fechaFin);
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
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (seleccion != null) {
      setState(() {
        _fecha = DateUtils.dateOnly(seleccion);
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
        if (_horaFin != null) {
          final inicio = _combinarFechaHora(seleccion);
          final fin = _combinarFechaHora(_horaFin!);
          if (inicio != null && fin != null && !fin.isAfter(inicio)) {
            _horaFin = TimeOfDay(
              hour: (seleccion.hour + 1) % 24,
              minute: seleccion.minute,
            );
          }
        }
      });
    }
  }

  Future<void> _seleccionarHoraFin() async {
    final base = _horaFin ?? (_horaInicio != null
        ? TimeOfDay(hour: (_horaInicio!.hour + 1) % 24, minute: _horaInicio!.minute)
        : TimeOfDay.now());
    final seleccion = await showTimePicker(
      context: context,
      initialTime: base,
    );
    if (seleccion != null) {
      setState(() {
        _horaFin = seleccion;
      });
    }
  }

  DateTime? _combinarFechaHora(TimeOfDay hora) {
    final fecha = _fecha ?? widget.cita?.fechaInicio ?? DateTime.now();
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
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
    if (_fecha == null) {
      return 'Selecciona la fecha de la cita';
    }
    if (_horaInicio == null) {
      return 'Selecciona la hora de inicio';
    }
    if (_horaFin == null) {
      return 'Selecciona la hora de finalización';
    }
    final inicio = _combinarFechaHora(_horaInicio!);
    final fin = _combinarFechaHora(_horaFin!);
    if (inicio == null || fin == null) {
      return 'No fue posible construir el horario de la cita';
    }
    if (!fin.isAfter(inicio)) {
      return 'La hora de finalización debe ser posterior a la de inicio';
    }
    if (inicio.isBefore(DateTime.now())) {
      return 'Selecciona un horario posterior al actual';
    }
    return null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final detalleValido = _formKey.currentState?.validate() ?? false;
    final errorTemporal = _validarCamposTemporales();
    if (!detalleValido || errorTemporal != null) {
      if (errorTemporal != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorTemporal)),
        );
      }
      return;
    }

    final inicio = _combinarFechaHora(_horaInicio!);
    final fin = _combinarFechaHora(_horaFin!);
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

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });

    if (exito) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.cita != null;
    return SafeArea(
      top: false,
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
                        esEdicion ? 'Editar cita médica' : 'Nueva cita médica',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarHoraInicio,
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(
                          _horaInicio == null
                              ? 'Hora de inicio'
                              : _horaInicio!.format(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarHoraFin,
                        icon: const Icon(Icons.timer_off_outlined),
                        label: Text(
                          _horaFin == null
                              ? 'Hora de fin'
                              : _horaFin!.format(context),
                        ),
                      ),
                    ),
                  ],
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
                        : Icon(esEdicion ? Icons.save_outlined : Icons.add_circle_outline),
                    label: Text(esEdicion ? 'Guardar cambios' : 'Crear cita'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
