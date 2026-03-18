import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/historial_cita.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_widgets.dart';

class CitasHistorialModalWidget extends StatelessWidget {
  const CitasHistorialModalWidget({
    super.key,
    required this.title,
    required this.content,
    required this.onClose,
  });

  final String title;
  final Widget content;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double dialogWidth = (screenSize.width - 32).clamp(300.0, 520.0);
    final double dialogHeight = (screenSize.height * 0.72).clamp(360.0, 560.0);
    final double responsiveTextScale = (screenSize.width / 390).clamp(
      0.90,
      1.08,
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      title: Text(title),
      content: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(responsiveTextScale)),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: content,
        ),
      ),
      actions: [TextButton(onPressed: onClose, child: const Text('Cerrar'))],
    );
  }
}

class CitasHistorialModalDialog extends StatefulWidget {
  const CitasHistorialModalDialog({
    super.key,
    required this.cita,
    required this.service,
    required this.theme,
    required this.dateFormat,
    required this.inicioDia,
    required this.finDia,
    required this.formatoFechaHoraHistorial,
    required this.tituloHistorial,
    required this.formatearDetalleCambio,
  });

  final CitaMedica cita;
  final CitasService service;
  final ThemeController theme;
  final DateFormat dateFormat;
  final DateTime Function(DateTime fecha) inicioDia;
  final DateTime Function(DateTime fecha) finDia;
  final String Function(DateTime? fecha) formatoFechaHoraHistorial;
  final String Function(HistorialCita item) tituloHistorial;
  final String? Function(HistorialCambio detalleCambio) formatearDetalleCambio;

  @override
  State<CitasHistorialModalDialog> createState() =>
      _CitasHistorialModalDialogState();
}

class _CitasHistorialModalDialogState extends State<CitasHistorialModalDialog> {
  final TextEditingController _rolController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _estadoAnterior;
  int _page = 1;
  static const int _limit = 10;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  List<HistorialCita> _historial = [];

  bool get _hasMore => _historial.length < _total;

  @override
  void initState() {
    super.initState();
    unawaited(_cargarHistorial(reset: true));
  }

  @override
  void dispose() {
    _rolController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial({bool reset = false}) async {
    if (_loading || _loadingMore) return;
    if (reset) {
      _page = 1;
      _historial = [];
    }
    setState(() {
      if (_page == 1) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
    });

    final filtros = <String, String>{
      if (_estadoAnterior != null && _estadoAnterior!.trim().isNotEmpty)
        'estadoAnterior': _estadoAnterior!.trim(),
      if (_rolController.text.trim().isNotEmpty)
        'rolEjecutor': _rolController.text.trim(),
      if (_fechaInicio != null)
        'fechaInicio': widget
            .inicioDia(_fechaInicio!)
            .toUtc()
            .toIso8601String(),
      if (_fechaFin != null)
        'fechaFin': widget.finDia(_fechaFin!).toUtc().toIso8601String(),
    };

    final result = await widget.service.obtenerHistorialCita(
      id: widget.cita.id,
      page: _page,
      limit: _limit,
      filtros: filtros,
    );

    if (!mounted) return;
    setState(() {
      if (_page == 1) {
        _historial = result.historial;
      } else {
        _historial = [..._historial, ...result.historial];
      }
      _total = result.total;
      _loading = false;
      _loadingMore = false;
      _page += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isNarrow = MediaQuery.sizeOf(context).width < 680;

    return CitasHistorialModalWidget(
      title: 'Historial de la cita',
      onClose: () => Navigator.of(context).pop(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            children: [
              if (isNarrow)
                ..._buildDatePickersColumn(context)
              else
                ..._buildDatePickersRow(context),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _estadoAnterior,
                decoration: const InputDecoration(
                  labelText: 'Estado anterior',
                  border: OutlineInputBorder(),
                ),
                items: CitasEstado.valuesAsString
                    .map(
                      (estado) =>
                          DropdownMenuItem(value: estado, child: Text(estado)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _estadoAnterior = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rolController,
                decoration: const InputDecoration(
                  labelText: 'Rol ejecutor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _estadoAnterior = null;
                        _fechaInicio = null;
                        _fechaFin = null;
                        _rolController.clear();
                        _fechaInicioController.clear();
                        _fechaFinController.clear();
                      });
                      unawaited(_cargarHistorial(reset: true));
                    },
                    child: const Text('Limpiar'),
                  ),
                  ElevatedButton(
                    onPressed: () => unawaited(_cargarHistorial(reset: true)),
                    child: const Text('Aplicar filtros'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_historial.isEmpty)
            const Expanded(
              child: Center(child: Text('No hay historial disponible.')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _historial.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _historial.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: _loadingMore
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: () => unawaited(_cargarHistorial()),
                                child: const Text('Cargar más'),
                              ),
                      ),
                    );
                  }

                  final item = _historial[index];
                  final detalles = <String>[
                    if (item.estadoAnterior.trim().isNotEmpty)
                      'Estado anterior: ${item.estadoAnterior}',
                    if (item.comentario.trim().isNotEmpty)
                      'Comentario: ${item.comentario}',
                  ];
                  final cambiosFormateados = item.detalleCambios
                      .map(widget.formatearDetalleCambio)
                      .whereType<String>()
                      .toList();
                  detalles.addAll(cambiosFormateados);
                  if (detalles.isEmpty) {
                    detalles.add('Sin detalles adicionales');
                  }

                  final auditoriaCita = item.citaId.trim().isNotEmpty
                      ? 'Cita #${item.citaId}'
                      : '';
                  final ejecutor = item.ejecutorNombre.trim().isNotEmpty
                      ? item.ejecutorNombre
                      : 'Sistema';
                  final subtitulo = auditoriaCita.isNotEmpty
                      ? '$auditoriaCita · $ejecutor'
                      : ejecutor;

                  return CitasHistorialTimelineItem(
                    fecha: widget.formatoFechaHoraHistorial(item.fechaCreacion),
                    titulo: widget.tituloHistorial(item),
                    subtitulo: subtitulo,
                    detalles: detalles,
                    theme: widget.theme,
                    isLast: index == _historial.length - 1,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDatePickersColumn(BuildContext context) {
    return [
      TextFormField(
        controller: _fechaInicioController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Fecha inicio',
          border: OutlineInputBorder(),
        ),
        onTap: () => _pickDate(context, isStart: true),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _fechaFinController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Fecha fin',
          border: OutlineInputBorder(),
        ),
        onTap: () => _pickDate(context, isStart: false),
      ),
    ];
  }

  List<Widget> _buildDatePickersRow(BuildContext context) {
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _fechaInicioController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha inicio',
                border: OutlineInputBorder(),
              ),
              onTap: () => _pickDate(context, isStart: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _fechaFinController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha fin',
                border: OutlineInputBorder(),
              ),
              onTap: () => _pickDate(context, isStart: false),
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final DateTime? initial = isStart ? _fechaInicio : _fechaFin;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _fechaInicio = picked;
        _fechaInicioController.text = widget.dateFormat.format(picked);
      } else {
        _fechaFin = picked;
        _fechaFinController.text = widget.dateFormat.format(picked);
      }
    });
  }
}
