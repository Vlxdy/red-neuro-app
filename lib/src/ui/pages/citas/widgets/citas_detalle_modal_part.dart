part of '../citas_page.dart';

extension _CitasPageDetalleModalPart on _CitasPageState {
  Future<void> _mostrarDetalleCita(CitaMedica cita) async {
    final pacienteNombre = _nombrePaciente(cita);
    final pacienteDocumento = _valorDetalle(cita.pacienteNroDocumento);
    final pacienteTelefono = _valorDetalle(cita.pacienteTelefono);
    final pacienteGenero = _valorDetalle(_formatearGenero(cita.pacienteGenero));
    final pacienteFechaNacimiento = _valorDetalle(
      _formatearFechaPaciente(cita.pacienteFechaNacimiento),
    );
    final pacienteEdad = _valorDetalle(
      _calcularEdadPaciente(cita.pacienteFechaNacimiento),
    );
    final ocupacionNombre = _valorDetalle(
      cita.ocupacionNombre ?? cita.ocupacionId,
    );
    final etiquetaPrestacion = _etiquetaPrestacion(
      cita.servicioTipo ?? cita.tipoCita,
    );
    final servicioNombre = _valorDetalle(
      cita.servicioNombre ?? cita.servicioId,
    );
    final servicioDuracion = cita.servicioDuracionMinutos;
    final lugarNombre = _valorDetalle(cita.lugarNombre ?? cita.lugarId);
    final lugarSigla = _valorDetalle(cita.lugarSigla);
    final lugarTipo = _valorDetalle(cita.lugarTipo);
    final lugarDireccion = _valorDetalle(cita.lugarDireccion);
    final lugarDisplay = (lugarSigla != null && lugarNombre != null)
        ? '${lugarSigla.toUpperCase()} • $lugarNombre'
        : lugarNombre;
    final ocupacionColor = _colorOcupacion(cita);
    final personalAsignado = _nombreMedico(cita);

    final tieneDatosServicio =
        servicioNombre != null ||
        ocupacionNombre != null ||
        (servicioDuracion ?? 0) > 0;
    final tieneDatosLugar =
        lugarNombre != null ||
        lugarSigla != null ||
        lugarTipo != null ||
        lugarDireccion != null;
    final tieneDatosPaciente =
        pacienteNombre.isNotEmpty ||
        pacienteDocumento != null ||
        pacienteTelefono != null ||
        pacienteGenero != null ||
        pacienteFechaNacimiento != null ||
        pacienteEdad != null;
    final tienePersonalAsignado = personalAsignado.isNotEmpty;

    final detallesPacienteDisponibles =
        <({IconData icon, String label, String value})>[
          if (pacienteTelefono != null)
            (
              icon: PhosphorIconsRegular.phone,
              label: 'Teléfono',
              value: pacienteTelefono,
            ),
          if (pacienteDocumento != null)
            (
              icon: PhosphorIconsRegular.identificationCard,
              label: 'Documento',
              value: pacienteDocumento,
            ),
          if (pacienteGenero != null)
            (
              icon: PhosphorIconsRegular.genderIntersex,
              label: 'Género',
              value: pacienteGenero,
            ),
          if (pacienteFechaNacimiento != null)
            (
              icon: PhosphorIconsRegular.cake,
              label: 'Fecha nacimiento',
              value: pacienteFechaNacimiento,
            ),
          if (pacienteEdad != null)
            (
              icon: PhosphorIconsRegular.hourglass,
              label: 'Edad',
              value: pacienteEdad,
            ),
        ];
    final detallePacienteVisible = detallesPacienteDisponibles.isNotEmpty
        ? detallesPacienteDisponibles.first
        : null;
    final detallesPacienteExtra = detallesPacienteDisponibles.length > 1
        ? detallesPacienteDisponibles.sublist(1)
        : const <({IconData icon, String label, String value})>[];
    var mostrarMasPaciente = false;
    final detallesServicioExtra =
        <({IconData icon, String label, String value})>[
          if (ocupacionNombre != null)
            (
              icon: PhosphorIconsRegular.stethoscope,
              label: 'Ocupacion',
              value: ocupacionNombre,
            ),
          if ((servicioDuracion ?? 0) > 0)
            (
              icon: PhosphorIconsRegular.clock,
              label: 'Duración ${etiquetaPrestacion.toLowerCase()}',
              value: '${servicioDuracion!} min',
            ),
          if ((cita.servicioDescripcion ?? '').trim().isNotEmpty)
            (
              icon: PhosphorIconsRegular.note,
              label: 'Descripción',
              value: cita.servicioDescripcion!.trim(),
            ),
        ];
    var mostrarMasServicio = false;

    final acciones = <_CitaDetalleAccion>[
      if (cita.estado == 'SOLICITADA' && _puedeGestionarSolicitada(cita))
        _CitaDetalleAccion(
          label: 'Confirmar',
          icon: Icons.check_circle_outline,
          isPrimary: true,
          onTap: () async {
            final ok = await _confirmarCitaSolicitadaConOpciones(cita);
            return ok;
          },
        ),
      if (_puedeEditarCita(cita))
        _CitaDetalleAccion(
          label: 'Editar',
          icon: Icons.edit_outlined,
          onTap: () async {
            _abrirFormulario(cita: cita);
            return true;
          },
        ),
      if (cita.estado == 'SOLICITADA' && _puedeGestionarSolicitada(cita))
        _CitaDetalleAccion(
          label: 'Rechazar',
          icon: Icons.block_outlined,
          isDestructive: true,
          onTap: () => _rechazarCitaSolicitadaConConfirmacion(cita),
        ),
      if (cita.estado == 'CONFIRMADA' && _citaYaIniciada(cita))
        _CitaDetalleAccion(
          label: 'Completar',
          icon: Icons.task_alt_outlined,
          isPrimary: true,
          onTap: () async {
            await _completarCitaConConfirmacion(cita);
            return true;
          },
        ),
      if (cita.estado == 'CONFIRMADA' && _citaYaIniciada(cita))
        _CitaDetalleAccion(
          label: 'No asistió',
          icon: Icons.person_off_outlined,
          onTap: () async {
            await _marcarNoAsistioCitaConConfirmacion(cita);
            return true;
          },
        ),
      if (cita.estado == 'CONFIRMADA' ||
          cita.estado == 'CANCELADA' ||
          cita.estado == 'NO_ASISTIO')
        _CitaDetalleAccion(
          label: 'Reprogramar',
          icon: Icons.schedule_outlined,
          onTap: () async {
            await _reprogramarCitaConConfirmacion(cita);
            return true;
          },
        ),
      if (cita.estado == 'CONFIRMADA')
        _CitaDetalleAccion(
          label: 'Cancelar',
          icon: Icons.cancel_outlined,
          isDestructive: true,
          onTap: () async {
            await _cancelarCitaConConfirmacion(cita);
            return true;
          },
        ),
      if (cita.estado == 'BORRADOR')
        _CitaDetalleAccion(
          label: 'Eliminar borrador',
          icon: Icons.delete_outline,
          isDestructive: true,
          onTap: () async {
            await _eliminarBorradorConConfirmacion(cita);
            return true;
          },
        ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.94,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tituloCita(cita),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ver historial',
                          onPressed: () => _mostrarHistorialCita(cita),
                          icon: const Icon(Icons.history_outlined),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          CitasEstadoBadge(
                            estado: cita.estado,
                            color: _colorEstado(cita.estado),
                          ),
                          if (ocupacionNombre?.isNotEmpty ?? false)
                            CitasOcupacionTag(
                              label: ocupacionNombre!,
                              color: ocupacionColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CitasDetalleSection(
                            title: '',
                            theme: _theme,
                            children: [
                              CitasDetalleGrid(
                                minItemWidth: 110,
                                columns: 2,
                                children: [
                                  CitasDetalleRow(
                                    icon: PhosphorIconsRegular.calendar,
                                    label: 'Fecha',
                                    value: _formatoFechaCita(cita.fechaInicio),
                                    theme: _theme,
                                  ),
                                  CitasDetalleRow(
                                    icon: PhosphorIconsRegular.clock,
                                    label: 'Hora',
                                    value: _formatoHorarioCita(
                                      cita.fechaInicio,
                                      cita.fechaFin,
                                    ),
                                    theme: _theme,
                                  ),
                                ],
                              ),
                              if (cita.detalle.trim().isNotEmpty)
                                CitasDetalleRow(
                                  icon: PhosphorIconsRegular.note,
                                  label: 'Detalle',
                                  value: cita.detalle.trim(),
                                  theme: _theme,
                                ),
                            ],
                          ),
                          if (tieneDatosServicio)
                            CitasDetalleSection(
                              title: '',
                              theme: _theme,
                              children: [
                                Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: detallesServicioExtra.isNotEmpty
                                            ? 40
                                            : 0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (servicioNombre != null)
                                            CitasDetalleRow(
                                              icon:
                                                  PhosphorIconsRegular.testTube,
                                              label: etiquetaPrestacion,
                                              value: servicioNombre,
                                              theme: _theme,
                                            ),
                                          if (mostrarMasServicio &&
                                              detallesServicioExtra.isNotEmpty)
                                            CitasDetalleGrid(
                                              minItemWidth: 170,
                                              columns: 2,
                                              children: detallesServicioExtra
                                                  .map(
                                                    (item) => CitasDetalleRow(
                                                      icon: item.icon,
                                                      label: item.label,
                                                      value: item.value,
                                                      theme: _theme,
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (detallesServicioExtra.isNotEmpty)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          tooltip: mostrarMasServicio
                                              ? 'Ver menos servicio'
                                              : 'Ver más servicio',
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: EdgeInsets.zero,
                                          icon: Icon(
                                            mostrarMasServicio
                                                ? Icons.expand_less_rounded
                                                : Icons.expand_more_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setStateSheet(
                                              () => mostrarMasServicio =
                                                  !mostrarMasServicio,
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          if (tieneDatosLugar)
                            CitasDetalleSection(
                              title: '',
                              theme: _theme,
                              children: [
                                CitasDetalleGrid(
                                  children: [
                                    if (lugarDisplay != null)
                                      CitasDetalleRow(
                                        icon: PhosphorIconsRegular.mapPin,
                                        label: 'Lugar',
                                        value: lugarDisplay,
                                        theme: _theme,
                                      ),
                                    if (lugarTipo != null)
                                      CitasDetalleRow(
                                        icon: PhosphorIconsRegular.buildings,
                                        label: 'Tipo',
                                        value: lugarTipo,
                                        theme: _theme,
                                      ),
                                  ],
                                ),
                                if (lugarDireccion != null)
                                  CitasDetalleRow(
                                    icon: PhosphorIconsRegular.mapTrifold,
                                    label: 'Dirección',
                                    value: lugarDireccion,
                                    theme: _theme,
                                  ),
                              ],
                            ),
                          if (tieneDatosPaciente)
                            CitasDetalleSection(
                              title: '',
                              theme: _theme,
                              children: [
                                Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: detallesPacienteExtra.isNotEmpty
                                            ? 40
                                            : 0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (pacienteNombre.isNotEmpty)
                                            CitasDetalleRow(
                                              icon: PhosphorIconsRegular
                                                  .userCircle,
                                              label: 'Paciente',
                                              value: pacienteNombre,
                                              theme: _theme,
                                            ),
                                          if (detallePacienteVisible != null)
                                            CitasDetalleRow(
                                              icon: detallePacienteVisible.icon,
                                              label:
                                                  detallePacienteVisible.label,
                                              value:
                                                  detallePacienteVisible.value,
                                              theme: _theme,
                                            ),
                                          if (mostrarMasPaciente &&
                                              detallesPacienteExtra.isNotEmpty)
                                            CitasDetalleGrid(
                                              minItemWidth: 170,
                                              columns: 2,
                                              children: detallesPacienteExtra
                                                  .map(
                                                    (item) => CitasDetalleRow(
                                                      icon: item.icon,
                                                      label: item.label,
                                                      value: item.value,
                                                      theme: _theme,
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (detallesPacienteExtra.isNotEmpty)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          tooltip: mostrarMasPaciente
                                              ? 'Ver menos paciente'
                                              : 'Ver más paciente',
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: EdgeInsets.zero,
                                          icon: Icon(
                                            mostrarMasPaciente
                                                ? Icons.expand_less_rounded
                                                : Icons.expand_more_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setStateSheet(
                                              () => mostrarMasPaciente =
                                                  !mostrarMasPaciente,
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          if (tienePersonalAsignado)
                            CitasDetalleSection(
                              title: '',
                              theme: _theme,
                              children: [
                                CitasDetalleRow(
                                  icon: PhosphorIconsRegular.stethoscope,
                                  label: 'Personal asignado',
                                  value: personalAsignado,
                                  theme: _theme,
                                ),
                              ],
                            ),
                          if (acciones.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Acciones',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: acciones.map((accion) {
                                final style = accion.isDestructive
                                    ? OutlinedButton.styleFrom(
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        visualDensity: VisualDensity.compact,
                                      )
                                    : OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      );
                                return accion.isPrimary
                                    ? FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          await accion.onTap();
                                        },
                                        icon: Icon(accion.icon, size: 18),
                                        label: Text(accion.label),
                                      )
                                    : OutlinedButton.icon(
                                        style: style,
                                        onPressed: () async {
                                          if (accion.cierraModal) {
                                            Navigator.of(context).pop();
                                          }
                                          final ok = await accion.onTap();
                                          if (!accion.cierraModal &&
                                              ok &&
                                              context.mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        icon: Icon(accion.icon, size: 18),
                                        label: Text(accion.label),
                                      );
                              }).toList(),
                            ),
                          ],
                        ],
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


}
