part of '../citas_page.dart';

extension _CitasPageHistorialModalPart on _CitasPageState {
  Future<void> _mostrarHistorialCita(CitaMedica cita) async {
    final rolController = TextEditingController();
    final fechaInicioController = TextEditingController();
    final fechaFinController = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;
    String? estadoAnterior;
    int page = 1;
    const limit = 10;
    int total = 0;
    bool loading = false;
    bool loadingMore = false;
    bool initialized = false;
    List<HistorialCita> historial = [];

    Future<void> cargarHistorial(
      StateSetter setStateDialog, {
      bool reset = false,
    }) async {
      if (loading || loadingMore) return;
      if (reset) {
        page = 1;
        historial = [];
      }
      setStateDialog(() {
        if (page == 1) {
          loading = true;
        } else {
          loadingMore = true;
        }
      });
      final filtros = <String, String>{
        if (estadoAnterior != null && estadoAnterior!.trim().isNotEmpty)
          'estadoAnterior': estadoAnterior!.trim(),
        if (rolController.text.trim().isNotEmpty)
          'rolEjecutor': rolController.text.trim(),
        if (fechaInicio != null)
          'fechaInicio': _inicioDia(fechaInicio!).toUtc().toIso8601String(),
        if (fechaFin != null)
          'fechaFin': _finDia(fechaFin!).toUtc().toIso8601String(),
      };
      final result = await _service.obtenerHistorialCita(
        id: cita.id,
        page: page,
        limit: limit,
        filtros: filtros,
      );
      setStateDialog(() {
        if (page == 1) {
          historial = result.historial;
        } else {
          historial = [...historial, ...result.historial];
        }
        total = result.total;
        loading = false;
        loadingMore = false;
        page = page + 1;
      });
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (!initialized) {
              initialized = true;
              unawaited(cargarHistorial(setStateDialog, reset: true));
            }
            final hasMore = historial.length < total;
            final Size screenSize = MediaQuery.sizeOf(context);
            final bool isNarrow = screenSize.width < 680;
            final double dialogWidth = (screenSize.width - 32).clamp(300.0, 520.0);
            final double dialogHeight =
                (screenSize.height * 0.72).clamp(360.0, 560.0);
            final double responsiveTextScale = (screenSize.width / 390).clamp(
              0.90,
              1.08,
            );

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              title: const Text('Historial de la cita'),
              content: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(responsiveTextScale),
                ),
                child: SizedBox(
                  width: dialogWidth,
                  height: dialogHeight,
                  child: Column(
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
                          Column(
                            children: [
                              TextFormField(
                                controller: fechaInicioController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Fecha inicio',
                                  border: OutlineInputBorder(),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    initialDate: fechaInicio ?? DateTime.now(),
                                  );
                                  if (picked == null) return;
                                  setStateDialog(() {
                                    fechaInicio = picked;
                                    fechaInicioController.text = _dateFormat
                                        .format(picked);
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: fechaFinController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Fecha fin',
                                  border: OutlineInputBorder(),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    initialDate: fechaFin ?? DateTime.now(),
                                  );
                                  if (picked == null) return;
                                  setStateDialog(() {
                                    fechaFin = picked;
                                    fechaFinController.text = _dateFormat
                                        .format(picked);
                                  });
                                },
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: fechaInicioController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha inicio',
                                    border: OutlineInputBorder(),
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      initialDate: fechaInicio ?? DateTime.now(),
                                    );
                                    if (picked == null) return;
                                    setStateDialog(() {
                                      fechaInicio = picked;
                                      fechaInicioController.text = _dateFormat
                                          .format(picked);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: fechaFinController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha fin',
                                    border: OutlineInputBorder(),
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      initialDate: fechaFin ?? DateTime.now(),
                                    );
                                    if (picked == null) return;
                                    setStateDialog(() {
                                      fechaFin = picked;
                                      fechaFinController.text = _dateFormat
                                          .format(picked);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: estadoAnterior,
                          decoration: const InputDecoration(
                            labelText: 'Estado anterior',
                            border: OutlineInputBorder(),
                          ),
                          items: CitaEstado.values
                              .map(
                                (estado) => DropdownMenuItem(
                                  value: estado,
                                  child: Text(estado),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setStateDialog(() => estadoAnterior = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: rolController,
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
                                setStateDialog(() {
                                  estadoAnterior = null;
                                  fechaInicio = null;
                                  fechaFin = null;
                                  rolController.clear();
                                  fechaInicioController.clear();
                                  fechaFinController.clear();
                                });
                                unawaited(
                                  cargarHistorial(setStateDialog, reset: true),
                                );
                              },
                              child: const Text('Limpiar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                unawaited(
                                  cargarHistorial(setStateDialog, reset: true),
                                );
                              },
                              child: const Text('Aplicar filtros'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (loading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (historial.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('No hay historial disponible.'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: historial.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == historial.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Center(
                                  child: loadingMore
                                      ? const CircularProgressIndicator()
                                      : TextButton(
                                          onPressed: () {
                                            unawaited(
                                              cargarHistorial(setStateDialog),
                                            );
                                          },
                                          child: const Text('Cargar más'),
                                        ),
                                ),
                              );
                            }
                            final item = historial[index];
                            final detalles = <String>[
                              if (item.estadoAnterior.trim().isNotEmpty)
                                'Estado anterior: ${item.estadoAnterior}',
                              if (item.comentario.trim().isNotEmpty)
                                'Comentario: ${item.comentario}',
                            ];
                            final cambiosFormateados = item.detalleCambios
                                .map(_formatearDetalleCambio)
                                .whereType<String>()
                                .toList();
                            detalles.addAll(cambiosFormateados);
                            if (detalles.isEmpty) {
                              detalles.add('Sin detalles adicionales');
                            }
                            return CitasHistorialTimelineItem(
                              fecha: _formatoFechaHoraHistorial(
                                item.fechaCreacion,
                              ),
                              titulo: _tituloHistorial(item),
                              subtitulo: item.ejecutorNombre.trim().isNotEmpty
                                  ? item.ejecutorNombre
                                  : 'Sistema',
                              detalles: detalles,
                              theme: _theme,
                              isLast: index == historial.length - 1,
                            );
                          },
                        ),
                      ),
                  ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );

    rolController.dispose();
    fechaInicioController.dispose();
    fechaFinController.dispose();
  }
}

