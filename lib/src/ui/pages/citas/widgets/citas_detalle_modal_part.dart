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
    final servicioNombre = _valorDetalle(cita.servicioNombre ?? cita.servicioId);
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

    final acciones = <CitaDetalleAccion>[
      if (cita.estado == 'SOLICITADA' && _puedeGestionarSolicitada(cita))
        CitaDetalleAccion(
          label: 'Confirmar',
          icon: Icons.check_circle_outline,
          isPrimary: true,
          onTap: () async {
            final ok = await _confirmarCitaSolicitadaConOpciones(cita);
            return ok;
          },
        ),
      if (_puedeEditarCita(cita))
        CitaDetalleAccion(
          label: 'Editar',
          icon: Icons.edit_outlined,
          onTap: () async {
            _abrirFormulario(cita: cita);
            return true;
          },
        ),
      if (cita.estado == 'SOLICITADA' && _puedeGestionarSolicitada(cita))
        CitaDetalleAccion(
          label: 'Rechazar',
          icon: Icons.block_outlined,
          isDestructive: true,
          onTap: () => _rechazarCitaSolicitadaConConfirmacion(cita),
        ),
      if (cita.estado == 'CONFIRMADA' && _citaYaIniciada(cita))
        CitaDetalleAccion(
          label: 'Completar',
          icon: Icons.task_alt_outlined,
          isPrimary: true,
          onTap: () async {
            await _completarCitaConConfirmacion(cita);
            return true;
          },
        ),
      if (cita.estado == 'CONFIRMADA' && _citaYaIniciada(cita))
        CitaDetalleAccion(
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
        CitaDetalleAccion(
          label: 'Reprogramar',
          icon: Icons.schedule_outlined,
          onTap: () async {
            await _reprogramarCitaConConfirmacion(cita);
            return true;
          },
        ),
      if (cita.estado == 'CONFIRMADA')
        CitaDetalleAccion(
          label: 'Cancelar',
          icon: Icons.cancel_outlined,
          isDestructive: true,
          onTap: () async {
            await _cancelarCitaConConfirmacion(cita);
            return true;
          },
        ),
      if (cita.estado == 'BORRADOR')
        CitaDetalleAccion(
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
        return CitasDetalleModal(
          cita: cita,
          theme: _theme,
          titulo: _tituloCita(cita),
          pacienteNombre: pacienteNombre,
          pacienteDocumento: pacienteDocumento,
          pacienteTelefono: pacienteTelefono,
          pacienteCorreo: pacienteCorreo,
          pacienteGenero: pacienteGenero,
          pacienteFechaNacimiento: pacienteFechaNacimiento,
          pacienteEdad: pacienteEdad,
          etiquetaPrestacion: etiquetaPrestacion,
          servicioNombre: servicioNombre,
          servicioDuracion: servicioDuracion,
          servicioDescripcion: cita.servicioDescripcion,
          lugarDisplay: lugarDisplay,
          lugarTipo: lugarTipo,
          lugarDireccion: lugarDireccion,
          personalAsignado: personalAsignado,
          personalDocumento: personalDocumento,
          personalTelefono: personalTelefono,
          personalCorreo: personalCorreo,
          personalOcupacion: personalOcupacion,
          personalAvatarUrl: personalAvatarUrl,
          inicialesPersonal: _inicialesPersonal(cita),
          fechaCita: _formatoFechaCita(cita.fechaInicio),
          horaCita: _formatoHorarioCita(cita.fechaInicio, cita.fechaFin),
          detalleCita: cita.detalle,
          estadoColor: _colorEstado(cita.estado),
          acciones: acciones,
          onClose: () => Navigator.of(context).pop(),
          onVerHistorial: () => _mostrarHistorialCita(cita),
          onCopiarDato: _copiarDato,
        );
      },
    );
  }
}
