part of '../citas_page.dart';

extension _CitasPageDetalleModalPart on _CitasPageState {
  Future<void> _mostrarDetalleCita(CitaMedica cita) async {
    final pacienteNombre = _nombrePaciente(cita);
    final pacienteDocumento = _valorDetalle(cita.pacienteNroDocumento);
    final pacienteTelefono = _valorDetalle(cita.pacienteTelefono);
    final pacienteCorreo = _valorDetalle(cita.pacienteCorreoElectronico);
    final pacienteGenero = _valorDetalle(_formatearGenero(cita.pacienteGenero));
    final pacienteFechaNacimiento = _valorDetalle(
      _formatearFechaPaciente(cita.pacienteFechaNacimiento),
    );
    final pacienteEdad = _valorDetalle(
      _calcularEdadPaciente(cita.pacienteFechaNacimiento),
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
    final personalAsignado = _nombreMedico(cita);
    final personalDocumento = _valorDetalle(cita.personalNroDocumento);
    final personalTelefono = _valorDetalle(cita.personalTelefono);
    final personalCorreo = _valorDetalle(cita.personalCorreoElectronico);
    final personalOcupacion = _valorDetalle(cita.personalOcupacion);
    final personalAvatarUrl = _resolveAvatarUrl(cita.personalUrlFoto);

    final tieneDatosServicio =
        servicioNombre != null || (servicioDuracion ?? 0) > 0;
    final tieneDatosLugar =
        lugarNombre != null ||
        lugarSigla != null ||
        lugarTipo != null ||
        lugarDireccion != null;
    final tieneDatosPaciente =
        pacienteNombre.isNotEmpty ||
        pacienteDocumento != null ||
        pacienteTelefono != null ||
        pacienteCorreo != null ||
        pacienteGenero != null ||
        pacienteFechaNacimiento != null ||
        pacienteEdad != null;
    final detallesPersonalDisponibles =
        <({IconData icon, String label, String value})>[
          if (personalDocumento != null)
            (
              icon: PhosphorIconsRegular.identificationCard,
              label: 'Documento',
              value: personalDocumento,
            ),
          if (personalOcupacion != null)
            (
              icon: PhosphorIconsRegular.briefcase,
              label: 'Ocupación',
              value: personalOcupacion,
            ),
        ];

    final tienePersonalAsignado =
        personalAsignado.isNotEmpty || detallesPersonalDisponibles.isNotEmpty;

    final detallesPacienteDisponibles =
        <({IconData icon, String label, String value})>[
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
    final tieneExtrasPaciente =
        detallesPacienteExtra.isNotEmpty ||
        pacienteTelefono != null ||
        pacienteCorreo != null;
    var mostrarMasPaciente = false;
    final detallesServicioExtra =
        <({IconData icon, String label, String value})>[
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
    final tieneExtrasPersonal =
        detallesPersonalDisponibles.isNotEmpty ||
        personalTelefono != null ||
        personalCorreo != null;
    var mostrarMasServicio = false;
    var mostrarDetallesPersonal = false;
    String? copiedField;

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
                                        right: tieneExtrasPaciente ? 40 : 0,
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
                                          if (mostrarMasPaciente &&
                                              pacienteTelefono != null)
                                            _buildCopyableDetalleRow(
                                              icon: PhosphorIconsRegular.phone,
                                              label: 'Teléfono',
                                              value: pacienteTelefono,
                                              copied:
                                                  copiedField ==
                                                  'pacienteTelefono',
                                              onTap: () async {
                                                await _copiarDato(
                                                  pacienteTelefono,
                                                );
                                                if (!mounted) return;
                                                setStateSheet(
                                                  () => copiedField =
                                                      'pacienteTelefono',
                                                );
                                              },
                                            ),
                                          if (mostrarMasPaciente &&
                                              pacienteCorreo != null)
                                            _buildCopyableDetalleRow(
                                              icon:
                                                  PhosphorIconsRegular.envelope,
                                              label: 'Correo',
                                              value: pacienteCorreo,
                                              copied:
                                                  copiedField ==
                                                  'pacienteCorreo',
                                              onTap: () async {
                                                await _copiarDato(
                                                  pacienteCorreo,
                                                );
                                                if (!mounted) return;
                                                setStateSheet(
                                                  () => copiedField =
                                                      'pacienteCorreo',
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (tieneExtrasPaciente)
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
                                Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: tieneExtrasPersonal ? 40 : 0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: _theme.primary20,
                                            child: personalAvatarUrl.isEmpty
                                                ? Text(
                                                    _inicialesPersonal(cita),
                                                    style: TextStyle(
                                                      color: _theme.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  )
                                                : ClipOval(
                                                    child: Image.network(
                                                      personalAvatarUrl,
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) =>
                                                          Text(
                                                            _inicialesPersonal(
                                                              cita,
                                                            ),
                                                            style: TextStyle(
                                                              color: _theme
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: CitasDetalleRow(
                                              icon: PhosphorIconsRegular
                                                  .stethoscope,
                                              label: 'Personal asignado',
                                              value: personalAsignado,
                                              theme: _theme,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (tieneExtrasPersonal)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          tooltip: mostrarDetallesPersonal
                                              ? 'Ver menos personal'
                                              : 'Ver más personal',
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: EdgeInsets.zero,
                                          icon: Icon(
                                            mostrarDetallesPersonal
                                                ? Icons.expand_less_rounded
                                                : Icons.expand_more_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setStateSheet(
                                              () => mostrarDetallesPersonal =
                                                  !mostrarDetallesPersonal,
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                                if (mostrarDetallesPersonal &&
                                    detallesPersonalDisponibles.isNotEmpty)
                                  CitasDetalleGrid(
                                    minItemWidth: 170,
                                    columns: 2,
                                    children: detallesPersonalDisponibles
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
                                if (mostrarDetallesPersonal &&
                                    personalTelefono != null)
                                  _buildCopyableDetalleRow(
                                    icon: PhosphorIconsRegular.phone,
                                    label: 'Teléfono',
                                    value: personalTelefono,
                                    copied: copiedField == 'personalTelefono',
                                    onTap: () async {
                                      await _copiarDato(personalTelefono);
                                      if (!mounted) return;
                                      setStateSheet(
                                        () => copiedField = 'personalTelefono',
                                      );
                                    },
                                  ),
                                if (mostrarDetallesPersonal &&
                                    personalCorreo != null)
                                  _buildCopyableDetalleRow(
                                    icon: PhosphorIconsRegular.envelope,
                                    label: 'Correo',
                                    value: personalCorreo,
                                    copied: copiedField == 'personalCorreo',
                                    onTap: () async {
                                      await _copiarDato(personalCorreo);
                                      if (!mounted) return;
                                      setStateSheet(
                                        () => copiedField = 'personalCorreo',
                                      );
                                    },
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

  Widget _buildCopyableDetalleRow({
    required IconData icon,
    required String label,
    required String value,
    required bool copied,
    required Future<void> Function() onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: _theme.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _theme.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(value, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 16,
                color: _theme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
