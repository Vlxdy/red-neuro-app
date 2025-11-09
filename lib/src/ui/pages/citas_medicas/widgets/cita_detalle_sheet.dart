import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/constants/citas_estado.dart';
import 'package:alimenta_app/src/models/cita.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/services/citas_medicas_service.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/widgets/cita_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CitaDetalleSheet extends StatefulWidget {
  const CitaDetalleSheet({
    super.key,
    required this.cita,
    required this.service,
    this.onRefresh,
  });

  final Cita cita;
  final CitasMedicasService service;
  final Future<void> Function()? onRefresh;

  @override
  State<CitaDetalleSheet> createState() => _CitaDetalleSheetState();
}

class _CitaDetalleSheetState extends State<CitaDetalleSheet> {
  final ThemeController theme = ThemeController.instance;
  final List<CitaHistorial> _historial = [];
  int _pagina = 1;
  int _total = 0;
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _procesandoAccion = false;
  static const int _limite = 10;
  late Cita _cita;

  @override
  void initState() {
    super.initState();
    _cita = widget.cita;
    _cargarHistorial();
  }

  @override
  void didUpdateWidget(covariant CitaDetalleSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cita.id != widget.cita.id) {
      _cita = widget.cita;
      _historial
        ..clear();
      _pagina = 1;
      _cargarHistorial();
    }
  }

  Future<void> _cargarHistorial({bool append = false}) async {
    if (!append) {
      setState(() {
        _cargando = true;
      });
    } else {
      setState(() {
        _cargandoMas = true;
      });
    }

    final respuesta = await widget.service.obtenerHistorial(
      _cita.id,
      pagina: _pagina,
      limite: _limite,
    );

    if (!mounted) return;

    setState(() {
      _total = respuesta.total;
      if (append) {
        _historial.addAll(respuesta.registros);
      } else {
        _historial
          ..clear()
          ..addAll(respuesta.registros);
      }
      _cargando = false;
      _cargandoMas = false;
    });
  }

  Future<void> _recargarDatos() async {
    final onRefresh = widget.onRefresh;
    if (onRefresh != null) {
      await onRefresh();
    }

    final detalleActualizado = await widget.service.obtenerDetalleCita(_cita.id);
    if (detalleActualizado != null && mounted) {
      setState(() {
        _cita = detalleActualizado;
      });
    }

    _pagina = 1;
    await _cargarHistorial();
  }

  String _formatearFecha(DateTime fecha) {
    final formato = DateFormat("dd 'de' MMMM yyyy, HH:mm", 'es');
    return formato.format(fecha);
  }

  Color _estadoColor(CitasEstado estado) {
    return estado.color(theme);
  }

  Color _estadoTexto(CitasEstado estado) {
    return estado.textColor(theme);
  }

  Widget _buildHistorial() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historial.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Sin registros en el historial.'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final evento = _historial[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _estadoColor(evento.estado),
            child: Text(
              evento.estado.label.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: _estadoTexto(evento.estado),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(evento.estado.label),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (evento.estadoAnterior != null && evento.estadoAnterior!.isNotEmpty)
                Text(
                  'Estado anterior: ${evento.estadoAnterior}',
                  style: TextStyle(color: theme.monochromatic900),
                ),
              Text(
                'Registrado por ${evento.usuarioEjecutor?.nombreCompleto.isNotEmpty == true ? evento.usuarioEjecutor!.nombreCompleto : evento.rolEjecutor}',
              ),
              Text(_formatearFecha(evento.fechaCreacion)),
              if (evento.comentario != null && evento.comentario!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    evento.comentario!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: _historial.length,
    );
  }

  bool get _puedeCargarMas => _historial.length < _total;

  Future<void> _editarCita() async {
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CitaFormSheet(
        service: widget.service,
        cita: _cita,
      ),
    );

    if (resultado == true) {
      await _recargarDatos();
    }
  }

  Future<void> _enviarCita() async {
    await _ejecutarAccion(() => widget.service.enviarCita(_cita.id));
  }

  Future<void> _reabrirCita() async {
    final comentario = await _solicitarComentario(
      titulo: 'Volver a borrador',
      label: 'Explica brevemente el motivo (opcional)',
      obligatorio: false,
    );
    if (comentario == null) return;
    await _ejecutarAccion(
      () => widget.service.reabrirCita(_cita.id, comentario: comentario),
    );
  }

  Future<void> _cancelarCita() async {
    final motivo = await _solicitarComentario(
      titulo: 'Cancelar cita',
      label: 'Motivo de la cancelación',
      obligatorio: true,
    );
    if (motivo == null) return;
    await _ejecutarAccion(
      () => widget.service.cancelarCita(_cita.id, motivo),
    );
  }

  Future<void> _ejecutarAccion(Future<bool> Function() accion) async {
    setState(() {
      _procesandoAccion = true;
    });

    final resultado = await accion();

    if (!mounted) return;

    setState(() {
      _procesandoAccion = false;
    });

    if (resultado) {
      await _recargarDatos();
    }
  }

  Future<String?> _solicitarComentario({
    required String titulo,
    required String label,
    required bool obligatorio,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: label),
              validator: (value) {
                if (!obligatorio) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es obligatorio';
                }
                if (value.trim().length < 5) {
                  return 'Describe el motivo con al menos 5 caracteres';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? true) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    ).whenComplete(() => controller.dispose());

    return resultado;
  }

  List<Widget> _buildAcciones() {
    final acciones = <Widget>[];
    final estado = _cita.estado;

    if (estado == CitasEstado.borrador) {
      acciones.add(
        FilledButton.icon(
          onPressed: _procesandoAccion ? null : _editarCita,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar cita'),
        ),
      );
    }

    if (estado == CitasEstado.borrador) {
      acciones.add(
        FilledButton.icon(
          onPressed: _procesandoAccion ? null : _enviarCita,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Enviar a revisión'),
        ),
      );
    }

    if (estado == CitasEstado.solicitada || estado == CitasEstado.rechazada) {
      acciones.add(
        OutlinedButton.icon(
          onPressed: _procesandoAccion ? null : _reabrirCita,
          icon: const Icon(Icons.undo_outlined),
          label: const Text('Volver a borrador'),
        ),
      );
    }

    if ({CitasEstado.borrador, CitasEstado.solicitada, CitasEstado.rechazada}
        .contains(estado)) {
      acciones.add(
        TextButton.icon(
          onPressed: _procesandoAccion ? null : _cancelarCita,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancelar cita'),
        ),
      );
    }

    return acciones;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final altura = MediaQuery.of(context).size.height * 0.85;
    final acciones = _buildAcciones();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: altura),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _cita.detalle.isNotEmpty
                              ? _cita.detalle
                              : 'Cita sin detalle',
                          style: themeData.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _estadoColor(_cita.estado),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _cita.estado.label,
                          style: TextStyle(
                            color: _estadoTexto(_cita.estado),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_formatearFecha(_cita.fechaInicio)} - ${DateFormat('HH:mm', 'es').format(_cita.fechaFin)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPersonaSection(
                    titulo: 'Nutricionista',
                    persona: _cita.medico,
                    icono: Icons.local_hospital_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildPersonaSection(
                    titulo: 'Paciente',
                    persona: _cita.paciente,
                    icono: Icons.person_outline,
                  ),
                  if (acciones.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Acciones disponibles',
                      style: themeData.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: acciones,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Historial de la cita',
                    style: themeData.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHistorial(),
                  if (_puedeCargarMas)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.center,
                        child: ElevatedButton.icon(
                          onPressed: _cargandoMas
                              ? null
                              : () {
                                  setState(() {
                                    _pagina += 1;
                                  });
                                  _cargarHistorial(append: true);
                                },
                          icon: _cargandoMas
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(
                            _cargandoMas ? 'Cargando...' : 'Cargar más historial',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonaSection({
    required String titulo,
    required CitaPersona persona,
    required IconData icono,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(persona.nombreCompleto.isNotEmpty
                  ? persona.nombreCompleto
                  : 'Sin asignar'),
              if (persona.telefono != null && persona.telefono!.isNotEmpty)
                Text('Teléfono: ${persona.telefono}'),
              if (persona.correoElectronico != null &&
                  persona.correoElectronico!.isNotEmpty)
                Text('Correo: ${persona.correoElectronico}'),
            ],
          ),
        ),
      ],
    );
  }
}
