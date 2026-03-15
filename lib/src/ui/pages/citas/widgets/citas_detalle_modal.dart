import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_badges.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_widgets.dart';

class CitaDetalleAccion {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDestructive;
  final bool cierraModal;
  final Future<bool> Function() onTap;

  const CitaDetalleAccion({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
    this.cierraModal = true,
  });
}

class CitasDetalleModal extends StatefulWidget {
  final CitaMedica cita;
  final ThemeController theme;
  final String titulo;
  final String pacienteNombre;
  final String? pacienteDocumento;
  final String? pacienteTelefono;
  final String? pacienteCorreo;
  final String? pacienteGenero;
  final String? pacienteFechaNacimiento;
  final String? pacienteEdad;
  final String etiquetaPrestacion;
  final String? servicioNombre;
  final int? servicioDuracion;
  final String? servicioDescripcion;
  final String? lugarDisplay;
  final String? lugarTipo;
  final String? lugarDireccion;
  final String personalAsignado;
  final String? personalDocumento;
  final String? personalTelefono;
  final String? personalCorreo;
  final String? personalOcupacion;
  final String personalAvatarUrl;
  final String inicialesPersonal;
  final String fechaCita;
  final String horaCita;
  final String detalleCita;
  final Color estadoColor;
  final List<CitaDetalleAccion> acciones;
  final VoidCallback onClose;
  final VoidCallback onVerHistorial;
  final Future<void> Function(String value) onCopiarDato;

  const CitasDetalleModal({
    super.key,
    required this.cita,
    required this.theme,
    required this.titulo,
    required this.pacienteNombre,
    required this.pacienteDocumento,
    required this.pacienteTelefono,
    required this.pacienteCorreo,
    required this.pacienteGenero,
    required this.pacienteFechaNacimiento,
    required this.pacienteEdad,
    required this.etiquetaPrestacion,
    required this.servicioNombre,
    required this.servicioDuracion,
    required this.servicioDescripcion,
    required this.lugarDisplay,
    required this.lugarTipo,
    required this.lugarDireccion,
    required this.personalAsignado,
    required this.personalDocumento,
    required this.personalTelefono,
    required this.personalCorreo,
    required this.personalOcupacion,
    required this.personalAvatarUrl,
    required this.inicialesPersonal,
    required this.fechaCita,
    required this.horaCita,
    required this.detalleCita,
    required this.estadoColor,
    required this.acciones,
    required this.onClose,
    required this.onVerHistorial,
    required this.onCopiarDato,
  });

  @override
  State<CitasDetalleModal> createState() => _CitasDetalleModalState();
}

class _CitasDetalleModalState extends State<CitasDetalleModal> {
  bool _mostrarMasPaciente = false;
  bool _mostrarMasServicio = false;
  bool _mostrarDetallesPersonal = false;
  String? _copiedField;

  @override
  Widget build(BuildContext context) {
    final tieneDatosServicio =
        widget.servicioNombre != null || (widget.servicioDuracion ?? 0) > 0;
    final tieneDatosLugar =
        widget.lugarDisplay != null ||
        widget.lugarTipo != null ||
        widget.lugarDireccion != null;
    final tieneDatosPaciente =
        widget.pacienteNombre.isNotEmpty ||
        widget.pacienteDocumento != null ||
        widget.pacienteTelefono != null ||
        widget.pacienteCorreo != null ||
        widget.pacienteGenero != null ||
        widget.pacienteFechaNacimiento != null ||
        widget.pacienteEdad != null;

    final detallesPersonalDisponibles =
        <({IconData icon, String label, String value})>[
          if (widget.personalDocumento != null)
            (
              icon: PhosphorIconsRegular.identificationCard,
              label: 'Documento',
              value: widget.personalDocumento!,
            ),
          if (widget.personalOcupacion != null)
            (
              icon: PhosphorIconsRegular.briefcase,
              label: 'Ocupación',
              value: widget.personalOcupacion!,
            ),
        ];
    final tienePersonalAsignado =
        widget.personalAsignado.isNotEmpty || detallesPersonalDisponibles.isNotEmpty;

    final detallesPacienteDisponibles =
        <({IconData icon, String label, String value})>[
          if (widget.pacienteDocumento != null)
            (
              icon: PhosphorIconsRegular.identificationCard,
              label: 'Documento',
              value: widget.pacienteDocumento!,
            ),
          if (widget.pacienteGenero != null)
            (
              icon: PhosphorIconsRegular.genderIntersex,
              label: 'Género',
              value: widget.pacienteGenero!,
            ),
          if (widget.pacienteFechaNacimiento != null)
            (
              icon: PhosphorIconsRegular.cake,
              label: 'Fecha nacimiento',
              value: widget.pacienteFechaNacimiento!,
            ),
          if (widget.pacienteEdad != null)
            (
              icon: PhosphorIconsRegular.hourglass,
              label: 'Edad',
              value: widget.pacienteEdad!,
            ),
        ];
    final detallePacienteVisible =
        detallesPacienteDisponibles.isNotEmpty ? detallesPacienteDisponibles.first : null;
    final detallesPacienteExtra = detallesPacienteDisponibles.length > 1
        ? detallesPacienteDisponibles.sublist(1)
        : const <({IconData icon, String label, String value})>[];

    final tieneExtrasPaciente =
        detallesPacienteExtra.isNotEmpty ||
        widget.pacienteTelefono != null ||
        widget.pacienteCorreo != null;

    final detallesServicioExtra =
        <({IconData icon, String label, String value})>[
          if ((widget.servicioDuracion ?? 0) > 0)
            (
              icon: PhosphorIconsRegular.clock,
              label: 'Duración ${widget.etiquetaPrestacion.toLowerCase()}',
              value: '${widget.servicioDuracion!} min',
            ),
          if ((widget.servicioDescripcion ?? '').trim().isNotEmpty)
            (
              icon: PhosphorIconsRegular.note,
              label: 'Descripción',
              value: widget.servicioDescripcion!.trim(),
            ),
        ];
    final tieneExtrasPersonal =
        detallesPersonalDisponibles.isNotEmpty ||
        widget.personalTelefono != null ||
        widget.personalCorreo != null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.titulo,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ver historial',
                    onPressed: widget.onVerHistorial,
                    icon: const Icon(Icons.history_outlined),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CitasEstadoBadge(
                  estado: widget.cita.estado,
                  color: widget.estadoColor,
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
                      theme: widget.theme,
                      children: [
                        CitasDetalleGrid(
                          minItemWidth: 110,
                          columns: 2,
                          children: [
                            CitasDetalleRow(
                              icon: PhosphorIconsRegular.calendar,
                              label: 'Fecha',
                              value: widget.fechaCita,
                              theme: widget.theme,
                            ),
                            CitasDetalleRow(
                              icon: PhosphorIconsRegular.clock,
                              label: 'Hora',
                              value: widget.horaCita,
                              theme: widget.theme,
                            ),
                          ],
                        ),
                        if (widget.detalleCita.trim().isNotEmpty)
                          CitasDetalleRow(
                            icon: PhosphorIconsRegular.note,
                            label: 'Detalle',
                            value: widget.detalleCita.trim(),
                            theme: widget.theme,
                          ),
                      ],
                    ),
                    if (tieneDatosServicio)
                      _buildServicio(
                        detallesServicioExtra: detallesServicioExtra,
                        servicioNombre: widget.servicioNombre,
                      ),
                    if (tieneDatosLugar)
                      CitasDetalleSection(
                        title: '',
                        theme: widget.theme,
                        children: [
                          CitasDetalleGrid(
                            children: [
                              if (widget.lugarDisplay != null)
                                CitasDetalleRow(
                                  icon: PhosphorIconsRegular.mapPin,
                                  label: 'Lugar',
                                  value: widget.lugarDisplay!,
                                  theme: widget.theme,
                                ),
                              if (widget.lugarTipo != null)
                                CitasDetalleRow(
                                  icon: PhosphorIconsRegular.buildings,
                                  label: 'Tipo',
                                  value: widget.lugarTipo!,
                                  theme: widget.theme,
                                ),
                            ],
                          ),
                          if (widget.lugarDireccion != null)
                            CitasDetalleRow(
                              icon: PhosphorIconsRegular.mapTrifold,
                              label: 'Dirección',
                              value: widget.lugarDireccion!,
                              theme: widget.theme,
                            ),
                        ],
                      ),
                    if (tieneDatosPaciente)
                      _buildPaciente(
                        detallePacienteVisible: detallePacienteVisible,
                        detallesPacienteExtra: detallesPacienteExtra,
                        tieneExtrasPaciente: tieneExtrasPaciente,
                      ),
                    if (tienePersonalAsignado)
                      _buildPersonal(
                        detallesPersonalDisponibles: detallesPersonalDisponibles,
                        tieneExtrasPersonal: tieneExtrasPersonal,
                      ),
                    if (widget.acciones.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Acciones',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.acciones.map((accion) {
                          final style = accion.isDestructive
                              ? OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
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
    );
  }

  Widget _buildServicio({
    required List<({IconData icon, String label, String value})>
    detallesServicioExtra,
    required String? servicioNombre,
  }) {
    return CitasDetalleSection(
      title: '',
      theme: widget.theme,
      children: [
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: detallesServicioExtra.isNotEmpty ? 40 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (servicioNombre != null)
                    CitasDetalleRow(
                      icon: PhosphorIconsRegular.testTube,
                      label: widget.etiquetaPrestacion,
                      value: servicioNombre,
                      theme: widget.theme,
                    ),
                  if (_mostrarMasServicio && detallesServicioExtra.isNotEmpty)
                    CitasDetalleGrid(
                      minItemWidth: 170,
                      columns: 2,
                      children: detallesServicioExtra
                          .map(
                            (item) => CitasDetalleRow(
                              icon: item.icon,
                              label: item.label,
                              value: item.value,
                              theme: widget.theme,
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
                  tooltip:
                      _mostrarMasServicio ? 'Ver menos servicio' : 'Ver más servicio',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _mostrarMasServicio
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _mostrarMasServicio = !_mostrarMasServicio);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaciente({
    required ({IconData icon, String label, String value})?
    detallePacienteVisible,
    required List<({IconData icon, String label, String value})>
    detallesPacienteExtra,
    required bool tieneExtrasPaciente,
  }) {
    return CitasDetalleSection(
      title: '',
      theme: widget.theme,
      children: [
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: tieneExtrasPaciente ? 40 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.pacienteNombre.isNotEmpty)
                    CitasDetalleRow(
                      icon: PhosphorIconsRegular.userCircle,
                      label: 'Paciente',
                      value: widget.pacienteNombre,
                      theme: widget.theme,
                    ),
                  if (detallePacienteVisible != null)
                    CitasDetalleRow(
                      icon: detallePacienteVisible.icon,
                      label: detallePacienteVisible.label,
                      value: detallePacienteVisible.value,
                      theme: widget.theme,
                    ),
                  if (_mostrarMasPaciente && detallesPacienteExtra.isNotEmpty)
                    CitasDetalleGrid(
                      minItemWidth: 170,
                      columns: 2,
                      children: detallesPacienteExtra
                          .map(
                            (item) => CitasDetalleRow(
                              icon: item.icon,
                              label: item.label,
                              value: item.value,
                              theme: widget.theme,
                            ),
                          )
                          .toList(),
                    ),
                  if (_mostrarMasPaciente && widget.pacienteTelefono != null)
                    _buildCopyableDetalleRow(
                      icon: PhosphorIconsRegular.phone,
                      label: 'Teléfono',
                      value: widget.pacienteTelefono!,
                      copied: _copiedField == 'pacienteTelefono',
                      onTap: () async {
                        await widget.onCopiarDato(widget.pacienteTelefono!);
                        if (!mounted) return;
                        setState(() => _copiedField = 'pacienteTelefono');
                      },
                    ),
                  if (_mostrarMasPaciente && widget.pacienteCorreo != null)
                    _buildCopyableDetalleRow(
                      icon: PhosphorIconsRegular.envelope,
                      label: 'Correo',
                      value: widget.pacienteCorreo!,
                      copied: _copiedField == 'pacienteCorreo',
                      onTap: () async {
                        await widget.onCopiarDato(widget.pacienteCorreo!);
                        if (!mounted) return;
                        setState(() => _copiedField = 'pacienteCorreo');
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
                  tooltip:
                      _mostrarMasPaciente ? 'Ver menos paciente' : 'Ver más paciente',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _mostrarMasPaciente
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _mostrarMasPaciente = !_mostrarMasPaciente);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonal({
    required List<({IconData icon, String label, String value})>
    detallesPersonalDisponibles,
    required bool tieneExtrasPersonal,
  }) {
    return CitasDetalleSection(
      title: '',
      theme: widget.theme,
      children: [
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: tieneExtrasPersonal ? 40 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: widget.theme.primary20,
                    child: widget.personalAvatarUrl.isEmpty
                        ? Text(
                            widget.inicialesPersonal,
                            style: TextStyle(
                              color: widget.theme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : ClipOval(
                            child: Image.network(
                              widget.personalAvatarUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Text(
                                widget.inicialesPersonal,
                                style: TextStyle(
                                  color: widget.theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CitasDetalleRow(
                      icon: PhosphorIconsRegular.stethoscope,
                      label: 'Personal asignado',
                      value: widget.personalAsignado,
                      theme: widget.theme,
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
                  tooltip: _mostrarDetallesPersonal
                      ? 'Ver menos personal'
                      : 'Ver más personal',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _mostrarDetallesPersonal
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(
                      () => _mostrarDetallesPersonal = !_mostrarDetallesPersonal,
                    );
                  },
                ),
              ),
          ],
        ),
        if (_mostrarDetallesPersonal && detallesPersonalDisponibles.isNotEmpty)
          CitasDetalleGrid(
            minItemWidth: 170,
            columns: 2,
            children: detallesPersonalDisponibles
                .map(
                  (item) => CitasDetalleRow(
                    icon: item.icon,
                    label: item.label,
                    value: item.value,
                    theme: widget.theme,
                  ),
                )
                .toList(),
          ),
        if (_mostrarDetallesPersonal && widget.personalTelefono != null)
          _buildCopyableDetalleRow(
            icon: PhosphorIconsRegular.phone,
            label: 'Teléfono',
            value: widget.personalTelefono!,
            copied: _copiedField == 'personalTelefono',
            onTap: () async {
              await widget.onCopiarDato(widget.personalTelefono!);
              if (!mounted) return;
              setState(() => _copiedField = 'personalTelefono');
            },
          ),
        if (_mostrarDetallesPersonal && widget.personalCorreo != null)
          _buildCopyableDetalleRow(
            icon: PhosphorIconsRegular.envelope,
            label: 'Correo',
            value: widget.personalCorreo!,
            copied: _copiedField == 'personalCorreo',
            onTap: () async {
              await widget.onCopiarDato(widget.personalCorreo!);
              if (!mounted) return;
              setState(() => _copiedField = 'personalCorreo');
            },
          ),
      ],
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
              Icon(icon, size: 18, color: widget.theme.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: widget.theme.grey,
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
                color: widget.theme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
