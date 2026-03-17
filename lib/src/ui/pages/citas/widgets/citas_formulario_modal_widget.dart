import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/servicio.dart';
import 'package:red_neuro_app/src/models/lugar.dart';
import 'package:red_neuro_app/src/models/paciente.dart';
import 'package:red_neuro_app/src/models/personal_medico.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_autocomplete_selector_field.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/fecha_selector.dart';

class CitasFormularioModalWidget extends StatelessWidget {
  const CitasFormularioModalWidget({
    super.key,
    required this.backgroundColor,
    required this.title,
    required this.formKey,
    required this.autovalidateMode,
    required this.body,
    required this.onClose,
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
    this.headerActions = const [],
  });

  final Color backgroundColor;
  final String title;
  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidateMode;
  final Widget body;
  final VoidCallback onClose;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;
  final List<Widget> headerActions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .92,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: PopScope(
              canPop: true,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: formKey,
                  autovalidateMode: autovalidateMode,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            ...headerActions,
                            IconButton(
                              tooltip: 'Cerrar',
                              onPressed: onClose,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        body,
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onCancel,
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: onSubmit,
                                child: Text(submitLabel),
                              ),
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
      ),
    );
  }
}

Future<void> abrirCitasFormularioModal({
  required BuildContext context,
  required ThemeController theme,
  required CitasService service,
  required DateFormat dateFormat,
  required DateFormat timeFormat,
  required GlobalKey<ScaffoldMessengerState> messengerKey,
  required DateTime? selectedDay,
  required int currentTabIndex,
  required DateTime Function(DateTime baseDay) resolveDefaultStartTime,
  required String Function(String? value, String alias) validarRequerido,
  required String Function(String? fechaRaw) calcularEdadPaciente,
  required String Function(String? fechaRaw) formatearFechaPaciente,
  required String Function(String? genero) formatearGenero,
  required bool Function(CitaMedica cita) puedeGestionarSolicitada,
  required Color Function(String estado) colorEstado,
  required String Function(String value) formatearTipoCita,
  required Future<String?> Function({
    required bool esNueva,
    required String tipoCita,
    required String? pacienteNombre,
    required String servicioNombre,
    required String medicoNombre,
    required String? pacienteDocumento,
    required String? pacienteTelefono,
    required String? pacienteGenero,
    required String? lugarNombre,
    required String? lugarDireccion,
    required String detalle,
    required DateTime fechaInicio,
    int? duracionMinutos,
  })
  confirmarAccionCita,
  required Future<bool> Function({
    required String titulo,
    required String mensaje,
    required String accion,
  })
  confirmarAccionSimple,
  required Future<String?> Function() solicitarMotivoRechazo,
  required Future<bool> Function(dynamic response, String fallback)
  handleResponseError,
  required Future<void> Function() cargarCitasCalendario,
  required Future<void> Function({int? page}) cargarCitasListado,
  required Future<void> Function(CitaMedica cita) mostrarHistorialCita,
  required Future<bool> Function(CitaMedica cita) eliminarCitaEditable,
  CitaMedica? cita,
  DateTime? fechaBase,
}) async {
  String resolverIdUsuarioRol(Usuario profile) {
    final directo = (profile.idUsuarioRol ?? '').trim();
    if (directo.isNotEmpty) return directo;

    final roles = profile.roles;
    final roleId = (profile.idRol ?? '').trim();
    if (roles.isEmpty) return '';

    if (roleId.isNotEmpty) {
      for (final rol in roles) {
        if (rol.idRol == roleId) return rol.idUsuarioRol.trim();
      }
    }

    return roles.first.idUsuarioRol.trim();
  }

  PersonalMedico? resolverPersonalActual(Usuario profile) {
    final id = resolverIdUsuarioRol(profile);
    final nombres = profile.nombres.trim();
    if (id.isEmpty || nombres.isEmpty) return null;
    return PersonalMedico(
      id: id,
      nombres: nombres,
      primerApellido: profile.primerApellido.trim().isEmpty
          ? null
          : profile.primerApellido.trim(),
      segundoApellido: profile.segundoApellido.trim().isEmpty
          ? null
          : profile.segundoApellido.trim(),
      nroDocumento: profile.nroDocumento.trim().isEmpty
          ? null
          : profile.nroDocumento.trim(),
    );
  }

  var personalActual = resolverPersonalActual(Auth.instance.profile);
  if (personalActual == null) {
    final profile = await Auth.instance.profileAsync();
    personalActual = resolverPersonalActual(profile);
  }

  final formKey = GlobalKey<FormState>();
  final detalleController = TextEditingController(text: cita?.detalle ?? '');
  final medicoController = TextEditingController(
    text: (cita?.medicoNombre ?? '').trim().isNotEmpty
        ? cita!.medicoNombre!
        : cita?.medicoId ?? '',
  );
  String? medicoIdSeleccionado = (cita?.medicoId.isNotEmpty ?? false)
      ? cita?.medicoId
      : null;
  PersonalMedico? medicoSeleccionado;
  Paciente? pacienteSeleccionado;
  Lugar? lugarSeleccionado;
  final pacienteFieldKey = GlobalKey<FormFieldState<Paciente>>();
  final servicioFieldKey = GlobalKey<FormFieldState<Servicio>>();
  final pacienteAutocompleteController = TextEditingController(
    text: cita?.pacienteNombre ?? '',
  );
  DateTime? fechaInicio = cita?.fechaInicio;
  final baseSeleccionada = fechaBase ?? selectedDay;
  if (cita == null && baseSeleccionada != null) {
    final tieneHoraExplicita =
        baseSeleccionada.hour != 0 || baseSeleccionada.minute != 0;
    if (tieneHoraExplicita) {
      fechaInicio ??= DateTime(
        baseSeleccionada.year,
        baseSeleccionada.month,
        baseSeleccionada.day,
        baseSeleccionada.hour,
        baseSeleccionada.minute,
      );
    } else {
      fechaInicio ??= resolveDefaultStartTime(baseSeleccionada);
    }
  }
  String? estado = cita?.estado;
  String tipoCita = (cita?.tipoCita?.isNotEmpty ?? false)
      ? cita!.tipoCita!
      : 'CONSULTA';
  Servicio? servicioSeleccionado;
  if ((cita?.lugarId ?? '').trim().isNotEmpty) {
    lugarSeleccionado = Lugar(
      id: cita!.lugarId!.trim(),
      nombre: (cita.lugarNombre ?? '').trim(),
      sigla: '',
      direccion: '',
      tipo: '',
      estado: 'ACTIVO',
    );
  }
  if (cita?.servicioId != null && cita!.servicioId!.isNotEmpty) {
    servicioSeleccionado = Servicio(
      id: cita.servicioId!,
      nombre: cita.servicioNombre ?? 'Servicio ${cita.servicioId}',
      descripcion: '',
      duracionMinutos:
          cita.servicioDuracionMinutos ??
          Constantes.citasDuracionDefectoMinutos,
      estado: 'ACTIVO',
      categorias: const [],
    );
  }
  final servicioController = TextEditingController(
    text: servicioSeleccionado?.nombre ?? '',
  );
  final lugarController = TextEditingController(
    text: lugarSeleccionado?.nombre ?? '',
  );
  final List<Servicio> serviciosDisponibles = [];
  final List<Paciente> pacientesDisponibles = [];
  final List<PersonalMedico> medicosDisponibles = [];
  final List<Lugar> lugaresDisponibles = [];
  bool serviciosLoading = false;
  bool pacientesLoading = false;
  bool medicosLoading = false;
  bool lugaresLoading = false;
  bool serviciosError = false;
  bool pacientesError = false;
  bool medicosError = false;
  bool lugaresError = false;
  bool pacientesHasMore = true;
  bool medicosHasMore = true;
  int serviciosPage = 1;
  int pacientesPage = 1;
  int medicosPage = 1;
  int lugaresPage = 1;
  String serviciosFiltro = '';
  String pacientesFiltro = '';
  String medicosFiltro = '';
  String lugaresFiltro = '';
  Timer? serviciosDebounce;
  Timer? pacientesDebounce;
  Timer? medicosDebounce;
  Timer? lugaresDebounce;
  bool mostrarMasDatosPaciente = false;
  bool inicializado = false;
  if ((cita?.pacienteId ?? '').trim().isNotEmpty) {
    pacienteSeleccionado = Paciente(
      id: cita!.pacienteId!.trim(),
      nombres: (cita.pacienteNombre ?? '').trim(),
      primerApellido: null,
      segundoApellido: null,
      nroDocumento: null,
      fechaNacimiento: null,
      telefono: null,
      genero: null,
      observacion: null,
      estado: 'ACTIVO',
    );
  }

  String? accionFormulario;
  bool intentoEnvio = false;
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final modalContext = context;
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> cargarServicios({
            bool reset = false,
            void Function()? onUpdated,
          }) async {
            if (serviciosLoading) return;
            setStateDialog(() => serviciosLoading = true);
            if (reset) {
              serviciosPage = 1;
              serviciosDisponibles.clear();
            }
            final result = await service.obtenerServicios(
              tipo: tipoCita,
              page: serviciosPage,
              limit: 10,
              filtro: serviciosFiltro,
            );
            final requestError = result.status != StatusNetwork.connected;
            if (!context.mounted) return;
            setStateDialog(() {
              serviciosError = requestError;
              if (reset) {
                serviciosDisponibles
                  ..clear()
                  ..addAll(result.items);
              } else {
                serviciosDisponibles.addAll(result.items);
              }
              if (!requestError) {
                serviciosPage += 1;
              }
              serviciosLoading = false;
            });
            onUpdated?.call();
          }

          Future<void> cargarPacientes({
            bool reset = false,
            void Function()? onUpdated,
          }) async {
            if (pacientesLoading) return;
            setStateDialog(() => pacientesLoading = true);
            if (reset) {
              pacientesPage = 1;
              pacientesHasMore = true;
              pacientesDisponibles.clear();
            }
            final result = await service.obtenerPacientes(
              page: pacientesPage,
              limit: 10,
              filtro: pacientesFiltro,
            );
            final requestError = result.status != StatusNetwork.connected;
            if (!context.mounted) return;
            setStateDialog(() {
              pacientesError = requestError;
              if (reset) {
                pacientesDisponibles
                  ..clear()
                  ..addAll(result.items);
              } else {
                pacientesDisponibles.addAll(result.items);
              }
              pacientesHasMore =
                  !requestError && pacientesDisponibles.length < result.total;
              if (!requestError) {
                pacientesPage += 1;
              }
              pacientesLoading = false;
            });
            onUpdated?.call();
          }

          Future<void> cargarMedicos({
            bool reset = false,
            void Function()? onUpdated,
          }) async {
            if (medicosLoading) return;
            setStateDialog(() => medicosLoading = true);
            if (reset) {
              medicosPage = 1;
              medicosHasMore = true;
              medicosDisponibles.clear();
            }
            final result = await service.obtenerPersonalMedico(
              page: medicosPage,
              limit: 10,
              filtro: medicosFiltro,
            );
            final requestError = result.status != StatusNetwork.connected;
            if (!context.mounted) return;
            setStateDialog(() {
              medicosError = requestError;
              if (reset) {
                medicosDisponibles
                  ..clear()
                  ..addAll(result.items);
              } else {
                medicosDisponibles.addAll(result.items);
              }
              medicosHasMore =
                  !requestError && medicosDisponibles.length < result.total;
              if (!requestError) {
                medicosPage += 1;
              }
              medicosLoading = false;
            });
            onUpdated?.call();
          }

          Future<void> cargarLugares({bool reset = false}) async {
            if (lugaresLoading) return;
            setStateDialog(() => lugaresLoading = true);
            if (reset) {
              lugaresPage = 1;
              lugaresDisponibles.clear();
            }
            final result = await service.obtenerLugares(
              page: lugaresPage,
              limit: 10,
              filtro: lugaresFiltro,
            );
            final requestError = result.status != StatusNetwork.connected;
            if (!context.mounted) return;
            setStateDialog(() {
              lugaresError = requestError;
              if (reset) {
                lugaresDisponibles
                  ..clear()
                  ..addAll(result.items);
              } else {
                lugaresDisponibles.addAll(result.items);
              }
              if (!requestError) {
                lugaresPage += 1;
              }
              lugaresLoading = false;
            });
          }

          if (!inicializado) {
            inicializado = true;
            unawaited(cargarServicios(reset: true));
            unawaited(cargarLugares(reset: true));
          }

          void updateFechaInicioFecha() async {
            final base = fechaInicio ?? DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: base,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            final horaActual = TimeOfDay.fromDateTime(fechaInicio ?? base);
            setStateDialog(() {
              fechaInicio = DateTime(
                picked.year,
                picked.month,
                picked.day,
                horaActual.hour,
                horaActual.minute,
              );
            });
          }

          void updateFechaInicioHora() async {
            final base = fechaInicio ?? DateTime.now();
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(base),
            );
            if (picked == null) return;
            final fechaActual = fechaInicio ?? base;
            setStateDialog(() {
              fechaInicio = DateTime(
                fechaActual.year,
                fechaActual.month,
                fechaActual.day,
                picked.hour,
                picked.minute,
              );
            });
          }

          Future<void> abrirSelectorPaciente() async {
            if (pacientesDisponibles.isEmpty && !pacientesLoading) {
              await cargarPacientes(reset: true);
              if (!context.mounted) return;
            }
            final seleccion = await showModalBottomSheet<Paciente>(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                final searchController = TextEditingController(
                  text: pacientesFiltro,
                );
                return StatefulBuilder(
                  builder: (context, setStateSheet) {
                    Future<void> cargar({required bool reset}) async {
                      await cargarPacientes(
                        reset: reset,
                        onUpdated: () => setStateSheet(() {}),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SafeArea(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * .85,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                              child: Text(
                                'Selecciona un paciente',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: CustomTextInput(
                                controller: searchController,
                                title: 'Buscar paciente',
                                onChange: (value) {
                                  pacientesFiltro = value;
                                  pacientesDebounce?.cancel();
                                  pacientesDebounce = Timer(
                                    const Duration(milliseconds: 300),
                                    () => cargar(reset: true),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: Builder(
                                builder: (context) {
                                  if (pacientesDisponibles.isEmpty &&
                                      pacientesLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (pacientesDisponibles.isEmpty) {
                                    if (pacientesError) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'No se pudo obtener los resultados de las búsquedas.',
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 12),
                                              FilledButton.icon(
                                                onPressed: pacientesLoading
                                                    ? null
                                                    : () => cargar(reset: true),
                                                icon: const Icon(Icons.refresh_rounded),
                                                label: const Text('Reintentar'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 24),
                                        child: Text(
                                          'No se encontraron datos registrados.',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount:
                                        pacientesDisponibles.length +
                                        (pacientesHasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index ==
                                              pacientesDisponibles.length &&
                                          pacientesHasMore) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Center(
                                            child: TextButton.icon(
                                              onPressed: pacientesLoading
                                                  ? null
                                                  : () => cargar(reset: false),
                                              icon: const Icon(
                                                Icons.expand_more,
                                              ),
                                              label: const Text('Cargar más'),
                                            ),
                                          ),
                                        );
                                      }
                                      final option =
                                          pacientesDisponibles[index];
                                      return ListTile(
                                        title: Text(option.nombreCompleto),
                                        subtitle:
                                            (option.nroDocumento?.isNotEmpty ??
                                                false)
                                            ? Text(
                                                'Documento: ${option.nroDocumento}',
                                              )
                                            : null,
                                        onTap: () =>
                                            Navigator.pop(context, option),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
            if (seleccion == null) return;
            setStateDialog(() {
              pacienteSeleccionado = seleccion;
              mostrarMasDatosPaciente = false;
              pacienteAutocompleteController.text = seleccion.nombreCompleto;
            });
            pacienteFieldKey.currentState?.didChange(seleccion);
          }

          Future<void> abrirSelectorMedico() async {
            if (medicosDisponibles.isEmpty && !medicosLoading) {
              await cargarMedicos(reset: true);
              if (!context.mounted) return;
            }
            final seleccion = await showModalBottomSheet<PersonalMedico>(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                final searchController = TextEditingController(
                  text: medicosFiltro,
                );
                return StatefulBuilder(
                  builder: (context, setStateSheet) {
                    Future<void> cargar({required bool reset}) async {
                      await cargarMedicos(
                        reset: reset,
                        onUpdated: () => setStateSheet(() {}),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SafeArea(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * .85,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Seleccionar personal',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ),
                                    if (personalActual != null)
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context, personalActual);
                                        },
                                        icon: const Icon(Icons.person_pin_circle_outlined),
                                        label: const Text('Asignarme'),
                                      ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: CustomTextInput(
                                controller: searchController,
                                title: 'Buscar personal asignado',
                                onChange: (value) {
                                  medicosFiltro = value;
                                  medicosDebounce?.cancel();
                                  medicosDebounce = Timer(
                                    const Duration(milliseconds: 300),
                                    () => cargar(reset: true),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: Builder(
                                builder: (context) {
                                  if (medicosDisponibles.isEmpty &&
                                      medicosLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (medicosDisponibles.isEmpty) {
                                    if (medicosError) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'No se pudo obtener los resultados de las búsquedas.',
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 12),
                                              FilledButton.icon(
                                                onPressed: medicosLoading
                                                    ? null
                                                    : () => cargar(reset: true),
                                                icon: const Icon(Icons.refresh_rounded),
                                                label: const Text('Reintentar'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 24),
                                        child: Text(
                                          'No se encontraron datos registrados.',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount:
                                        medicosDisponibles.length +
                                        (medicosHasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == medicosDisponibles.length &&
                                          medicosHasMore) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Center(
                                            child: TextButton.icon(
                                              onPressed: medicosLoading
                                                  ? null
                                                  : () => cargar(reset: false),
                                              icon: const Icon(
                                                Icons.expand_more,
                                              ),
                                              label: const Text('Cargar más'),
                                            ),
                                          ),
                                        );
                                      }
                                      final option = medicosDisponibles[index];
                                      return ListTile(
                                        title: Text(option.nombreCompleto),
                                        subtitle:
                                            (option.nroDocumento?.isNotEmpty ??
                                                false)
                                            ? Text(
                                                'Documento: ${option.nroDocumento}',
                                              )
                                            : null,
                                        onTap: () =>
                                            Navigator.pop(context, option),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
            if (seleccion == null) return;
            setStateDialog(() {
              medicoSeleccionado = seleccion;
              medicoIdSeleccionado = seleccion.id;
              medicoController.text = seleccion.nombreCompleto;
            });
          }

          Future<Paciente?> abrirNuevoPaciente() async {
            final formKey = GlobalKey<FormState>();
            final nombresController = TextEditingController();
            final primerApellidoController = TextEditingController();
            final segundoApellidoController = TextEditingController();
            final nroDocumentoController = TextEditingController();
            final telefonoController = TextEditingController();
            String? genero;

            final crear = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Registrar paciente'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomTextInput(
                          controller: nombresController,
                          title: 'Nombres',
                          requiredData: true,
                          validate: validarRequerido,
                        ),
                        const SizedBox(height: 8),
                        CustomTextInput(
                          controller: primerApellidoController,
                          title: 'Primer apellido',
                          requiredData: true,
                          validate: validarRequerido,
                        ),
                        const SizedBox(height: 8),
                        CustomTextInput(
                          controller: segundoApellidoController,
                          title: 'Segundo apellido',
                        ),
                        const SizedBox(height: 8),
                        CustomTextInput(
                          controller: nroDocumentoController,
                          title: 'Documento',
                        ),
                        const SizedBox(height: 8),
                        CustomTextInput(
                          controller: telefonoController,
                          title: 'Teléfono',
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: genero,
                          decoration: const InputDecoration(
                            labelText: 'Género',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'M',
                              child: Text('Masculino'),
                            ),
                            DropdownMenuItem(
                              value: 'F',
                              child: Text('Femenino'),
                            ),
                            DropdownMenuItem(value: 'O', child: Text('Otro')),
                          ],
                          onChanged: (value) => genero = value,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            );

            if (crear != true) return null;

            final payload = <String, dynamic>{
              'nombres': nombresController.text.trim(),
              'primerApellido': primerApellidoController.text.trim(),
              if (segundoApellidoController.text.trim().isNotEmpty)
                'segundoApellido': segundoApellidoController.text.trim(),
              if (nroDocumentoController.text.trim().isNotEmpty)
                'nroDocumento': nroDocumentoController.text.trim(),
              if (telefonoController.text.trim().isNotEmpty)
                'telefono': telefonoController.text.trim(),
              if ((genero ?? '').trim().isNotEmpty) 'genero': genero,
            };

            final response = await service.crearPaciente(payload);
            final ok = await handleResponseError(
              response,
              'No se pudo registrar el paciente.',
            );
            if (!ok) return null;

            if (response.data['datos'] is Map<String, dynamic>) {
              return Paciente.fromJson(
                response.data['datos'] as Map<String, dynamic>,
              );
            }
            if (response.data['data'] is Map<String, dynamic>) {
              return Paciente.fromJson(
                response.data['data'] as Map<String, dynamic>,
              );
            }
            return Paciente(
              id: (response.data['id'] ?? '').toString(),
              nombres: nombresController.text.trim(),
              primerApellido: primerApellidoController.text.trim(),
              segundoApellido: segundoApellidoController.text.trim().isEmpty
                  ? null
                  : segundoApellidoController.text.trim(),
              nroDocumento: nroDocumentoController.text.trim().isEmpty
                  ? null
                  : nroDocumentoController.text.trim(),
              telefono: telefonoController.text.trim().isEmpty
                  ? null
                  : telefonoController.text.trim(),
              genero: genero,
              fechaNacimiento: null,
              observacion: null,
              estado: 'ACTIVO',
            );
          }

          Future<void> abrirSelectorServicio() async {
            if (serviciosDisponibles.isEmpty && !serviciosLoading) {
              await cargarServicios(reset: true);
              if (!context.mounted) return;
            }
            final seleccion = await showModalBottomSheet<Servicio>(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                final searchController = TextEditingController(
                  text: serviciosFiltro,
                );
                return StatefulBuilder(
                  builder: (context, setStateSheet) {
                    Future<void> cargar({required bool reset}) async {
                      await cargarServicios(
                        reset: reset,
                        onUpdated: () => setStateSheet(() {}),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SafeArea(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * .85,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: CustomTextInput(
                                  controller: searchController,
                                  title: 'Buscar servicio',
                                  onChange: (value) {
                                    serviciosFiltro = value;
                                    serviciosDebounce?.cancel();
                                    serviciosDebounce = Timer(
                                      const Duration(milliseconds: 300),
                                      () => cargar(reset: true),
                                    );
                                  },
                                ),
                              ),
                              Flexible(
                                child: Builder(
                                  builder: (context) {
                                    if (serviciosDisponibles.isEmpty &&
                                        serviciosLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (serviciosDisponibles.isEmpty) {
                                      if (serviciosError) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'No se pudo obtener los resultados de las búsquedas.',
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 12),
                                                FilledButton.icon(
                                                  onPressed: serviciosLoading
                                                      ? null
                                                      : () => cargar(reset: true),
                                                  icon: const Icon(Icons.refresh_rounded),
                                                  label: const Text('Reintentar'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: Text(
                                            'No se encontraron datos registrados.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: serviciosDisponibles.length,
                                      itemBuilder: (context, index) {
                                        final option = serviciosDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombre),
                                          subtitle: Text(option.descripcion),
                                          onTap: () => Navigator.pop(context, option),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
            if (seleccion == null) return;
            setStateDialog(() {
              servicioSeleccionado = seleccion;
              servicioController.text = seleccion.nombre;
            });
          }

          Future<void> abrirSelectorLugar() async {
            if (lugaresDisponibles.isEmpty && !lugaresLoading) {
              await cargarLugares(reset: true);
              if (!context.mounted) return;
            }
            final seleccion = await showModalBottomSheet<Lugar>(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                final searchController = TextEditingController(
                  text: lugaresFiltro,
                );
                return StatefulBuilder(
                  builder: (context, setStateSheet) {
                    Future<void> cargar({required bool reset}) async {
                      await cargarLugares(reset: reset);
                      setStateSheet(() {});
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SafeArea(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * .85,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: CustomTextInput(
                                  controller: searchController,
                                  title: 'Buscar lugar',
                                  onChange: (value) {
                                    lugaresFiltro = value;
                                    lugaresDebounce?.cancel();
                                    lugaresDebounce = Timer(
                                      const Duration(milliseconds: 300),
                                      () => cargar(reset: true),
                                    );
                                  },
                                ),
                              ),
                              Flexible(
                                child: Builder(
                                  builder: (context) {
                                    if (lugaresDisponibles.isEmpty &&
                                        lugaresLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (lugaresDisponibles.isEmpty) {
                                      if (lugaresError) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'No se pudo obtener los resultados de las búsquedas.',
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 12),
                                                FilledButton.icon(
                                                  onPressed: lugaresLoading
                                                      ? null
                                                      : () => cargar(reset: true),
                                                  icon: const Icon(Icons.refresh_rounded),
                                                  label: const Text('Reintentar'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: Text(
                                            'No se encontraron datos registrados.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: lugaresDisponibles.length,
                                      itemBuilder: (context, index) {
                                        final option = lugaresDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombre),
                                          subtitle: Text(option.direccion),
                                          onTap: () => Navigator.pop(context, option),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
            if (seleccion == null) return;
            setStateDialog(() {
              lugarSeleccionado = seleccion;
              lugarController.text = seleccion.nombre;
            });
          }

          bool validarFormulario() {
            final servicioValido =
                servicioFieldKey.currentState?.validate() ??
                servicioSeleccionado != null;
            final fechaValida = fechaInicio != null;
            return servicioValido && fechaValida;
          }

          Widget buildFormularioCompleto() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pacienteSeleccionado == null) ...[
                  FormField<Paciente>(
                    key: pacienteFieldKey,
                    builder: (state) {
                      return CitasAutocompleteSelectorField(
                        controller: pacienteAutocompleteController,
                        labelText: 'Paciente',
                        hintText: 'Selecciona un paciente si aplica',
                        errorText: state.errorText,
                        onTap: abrirSelectorPaciente,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final nuevo = await abrirNuevoPaciente();
                      if (nuevo == null) return;
                      setStateDialog(() {
                        pacienteSeleccionado = nuevo;
                        mostrarMasDatosPaciente = false;
                        pacienteAutocompleteController.text =
                            nuevo.nombreCompleto;
                        pacientesDisponibles.insert(0, nuevo);
                      });
                      pacienteFieldKey.currentState?.didChange(nuevo);
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Registrar paciente'),
                  ),
                ] else ...[
                  Builder(
                    builder: (context) {
                      final paciente = pacienteSeleccionado!;
                      final telefono = (paciente.telefono ?? '').trim();
                      final documento = (paciente.nroDocumento ?? '').trim();
                      final edad = calcularEdadPaciente(
                        paciente.fechaNacimiento,
                      );
                      final nacimiento = formatearFechaPaciente(
                        paciente.fechaNacimiento,
                      );
                      final genero = formatearGenero(paciente.genero).trim();

                      final detallesPrioritarios =
                          <({IconData icon, String label, String value})>[
                            if (paciente.nombreCompleto.trim().isNotEmpty)
                              (
                                icon: Icons.person_outline,
                                label: 'Paciente',
                                value: paciente.nombreCompleto.trim(),
                              ),
                            if (telefono.isNotEmpty)
                              (
                                icon: Icons.phone_outlined,
                                label: 'Teléfono',
                                value: telefono,
                              ),
                            if (documento.isNotEmpty)
                              (
                                icon: Icons.badge_outlined,
                                label: 'Documento',
                                value: documento,
                              ),
                            if (edad.isNotEmpty)
                              (
                                icon: Icons.access_time_outlined,
                                label: 'Edad',
                                value: edad,
                              ),
                            if (nacimiento.isNotEmpty)
                              (
                                icon: Icons.cake_outlined,
                                label: 'Nacimiento',
                                value: nacimiento,
                              ),
                            if (genero.isNotEmpty)
                              (
                                icon: Icons.wc_outlined,
                                label: 'Género',
                                value: genero,
                              ),
                          ];

                      final detallesExtras =
                          <({IconData icon, String label, String value})>[
                            ...detallesPrioritarios.skip(3),
                            if ((paciente.observacion ?? '').trim().isNotEmpty)
                              (
                                icon: Icons.sticky_note_2_outlined,
                                label: 'Observaciones',
                                value: paciente.observacion!.trim(),
                              ),
                          ];

                      final detallesVisibles = detallesPrioritarios
                          .take(3)
                          .toList();

                      return Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              12,
                              12,
                              detallesExtras.isNotEmpty ? 44 : 12,
                              8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.primary.withValues(alpha: .2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    ...detallesVisibles.map(
                                      (item) => SizedBox(
                                        width: 190,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              item.icon,
                                              size: 16,
                                              color: theme.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                  children: [
                                                    TextSpan(
                                                      text: '${item.label}: ',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    TextSpan(text: item.value),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (mostrarMasDatosPaciente &&
                                    detallesExtras.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: detallesExtras
                                        .map(
                                          (item) => SizedBox(
                                            width: 190,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  item.icon,
                                                  size: 16,
                                                  color: theme.grey,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              '${item.label}: ',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text: item.value,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (detallesExtras.isNotEmpty)
                                  IconButton(
                                    tooltip: mostrarMasDatosPaciente
                                        ? 'Ver menos paciente'
                                        : 'Ver más paciente',
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      mostrarMasDatosPaciente
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setStateDialog(
                                        () => mostrarMasDatosPaciente =
                                            !mostrarMasDatosPaciente,
                                      );
                                    },
                                  ),
                                IconButton(
                                  tooltip: 'Cambiar paciente',
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.swap_horiz),
                                  onPressed: () {
                                    setStateDialog(() {
                                      pacienteSeleccionado = null;
                                      mostrarMasDatosPaciente = false;
                                      pacienteAutocompleteController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      text: 'Tipo de cita',
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(
                        'Consulta',
                        style: TextStyle(
                          fontSize: 12,
                          color: tipoCita == 'CONSULTA'
                              ? theme.white
                              : theme.grey,
                        ),
                      ),
                      selectedColor: theme.primary,
                      backgroundColor: theme.grey.withValues(alpha: .12),
                      side: BorderSide(
                        color: tipoCita == 'CONSULTA'
                            ? theme.primary
                            : theme.grey.withValues(alpha: .35),
                      ),
                      selected: tipoCita == 'CONSULTA',
                      onSelected: (_) {
                        setStateDialog(() {
                          tipoCita = 'CONSULTA';
                          servicioSeleccionado = null;
                          servicioController.clear();
                          serviciosDisponibles.clear();
                          serviciosPage = 1;
                          unawaited(cargarServicios(reset: true));
                        });
                      },
                    ),
                    ChoiceChip(
                      label: Text(
                        'Estudio',
                        style: TextStyle(
                          fontSize: 12,
                          color: tipoCita == 'ESTUDIO'
                              ? theme.white
                              : theme.grey,
                        ),
                      ),
                      selectedColor: theme.primary,
                      backgroundColor: theme.grey.withValues(alpha: .12),
                      side: BorderSide(
                        color: tipoCita == 'ESTUDIO'
                            ? theme.primary
                            : theme.grey.withValues(alpha: .35),
                      ),
                      selected: tipoCita == 'ESTUDIO',
                      onSelected: (_) {
                        setStateDialog(() {
                          tipoCita = 'ESTUDIO';
                          servicioSeleccionado = null;
                          servicioController.clear();
                          serviciosDisponibles.clear();
                          serviciosPage = 1;
                          unawaited(cargarServicios(reset: true));
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FormField<Servicio>(
                  key: servicioFieldKey,
                  validator: (_) => servicioSeleccionado == null
                      ? 'Selecciona un servicio'
                      : null,
                  builder: (state) {
                    return CitasAutocompleteSelectorField(
                      controller: servicioController,
                      labelText: 'Servicio',
                      requiredData: true,
                      hintText: 'Selecciona un servicio',
                      errorText: state.errorText,
                      onTap: () async {
                        await abrirSelectorServicio();
                        state.didChange(servicioSeleccionado);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                FormField<Lugar>(
                  builder: (state) {
                    return CitasAutocompleteSelectorField(
                      controller: lugarController,
                      labelText: 'Lugar',
                      hintText: 'Selecciona un lugar',
                      errorText: state.errorText,
                      onClear: lugarSeleccionado == null
                          ? null
                          : () {
                              setStateDialog(() {
                                lugarSeleccionado = null;
                                lugarController.clear();
                              });
                              state.didChange(null);
                            },
                      onTap: () async {
                        await abrirSelectorLugar();
                        state.didChange(lugarSeleccionado);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                CustomTextInput(
                  controller: detalleController,
                  title: 'Detalle',
                  lines: 2,
                  expandsWithContent: true,
                ),
                const SizedBox(height: 12),
                FormField<PersonalMedico>(
                  builder: (state) {
                    return CitasAutocompleteSelectorField(
                      controller: medicoController,
                      labelText: 'Personal asignado',
                      hintText: 'Selecciona personal asignado',
                      errorText: state.errorText,
                      onClear: medicoIdSeleccionado == null
                          ? null
                          : () {
                              setStateDialog(() {
                                medicoSeleccionado = null;
                                medicoIdSeleccionado = null;
                                medicoController.clear();
                              });
                              state.didChange(null);
                            },
                      onTap: () async {
                        await abrirSelectorMedico();
                        state.didChange(medicoSeleccionado);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FechaSelector(
                        label: 'Fecha',
                        requiredData: true,
                        value: fechaInicio,
                        formatter: dateFormat,
                        onTap: updateFechaInicioFecha,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FechaSelector(
                        label: 'Hora',
                        requiredData: true,
                        value: fechaInicio,
                        formatter: timeFormat,
                        onTap: updateFechaInicioHora,
                        icon: Icons.schedule,
                      ),
                    ),
                  ],
                ),
                if (intentoEnvio && fechaInicio == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      'Selecciona fecha y hora de inicio.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (cita != null &&
                    (cita.estado == CitasEstado.solicitada.value ||
                        cita.estado == CitasEstado.programada.value))
                  const SizedBox(height: 12),
                if (cita != null &&
                    (cita.estado == CitasEstado.solicitada.value ||
                        cita.estado == CitasEstado.programada.value))
                  DropdownButtonFormField<String?>(
                    initialValue: estado,
                    decoration: CustomTextInputStyles.decoration(
                      label: 'Estado',
                    ),
                    items:
                        {
                          cita.estado,
                          if (cita.estado == CitasEstado.solicitada.value) ...[
                            CitasEstado.programada.value,
                            CitasEstado.rechazada.value,
                          ],
                          if (cita.estado == CitasEstado.programada.value) CitasEstado.cancelada.value,
                        }.map((estadoItem) {
                          final requierePermiso =
                              estadoItem == CitasEstado.programada.value ||
                              estadoItem == CitasEstado.rechazada.value;
                          final habilitado =
                              !requierePermiso ||
                              puedeGestionarSolicitada(cita) ||
                              estadoItem == cita.estado;
                          return DropdownMenuItem(
                            value: estadoItem,
                            enabled: habilitado,
                            child: Text(estadoItem),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setStateDialog(() => estado = value);
                    },
                  ),
              ],
            );
          }

          return CitasFormularioModalWidget(
            backgroundColor: theme.background,
            title: cita == null ? 'Registro de cita' : 'Actualizar cita',
            formKey: formKey,
            autovalidateMode: intentoEnvio
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            headerActions: [
              if (cita != null &&
                  (cita.estado == CitasEstado.borrador.value ||
                      cita.estado == CitasEstado.rechazada.value))
                IconButton(
                  tooltip: 'Eliminar cita',
                  onPressed: () async {
                    final ok = await eliminarCitaEditable(cita);
                    if (!modalContext.mounted || !ok) return;
                    Navigator.pop(modalContext, false);
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              if (cita?.estado == CitasEstado.rechazada.value)
                IconButton(
                  tooltip: 'Ver historial',
                  onPressed: () => mostrarHistorialCita(cita!),
                  icon: const Icon(Icons.history_outlined),
                ),
            ],
            onClose: () => Navigator.pop(modalContext, false),
            onCancel: () => Navigator.pop(modalContext, false),
            submitLabel: cita == null
                ? 'Crear cita'
                : (cita.estado == CitasEstado.borrador.value
                      ? 'Guardar'
                      : cita.estado == CitasEstado.rechazada.value
                      ? 'Confirmar'
                      : 'Actualizar cita'),
            onSubmit: () async {
              setStateDialog(() => intentoEnvio = true);
              if (!validarFormulario()) {
                return;
              }
              if (cita == null || cita.estado == CitasEstado.borrador.value) {
                final accion = await confirmarAccionCita(
                  esNueva: cita == null,
                  tipoCita: formatearTipoCita(tipoCita),
                  pacienteNombre: pacienteSeleccionado?.nombreCompleto,
                  servicioNombre:
                      servicioSeleccionado?.nombre ?? 'Sin servicio',
                  medicoNombre: medicoController.text.trim(),
                  pacienteDocumento: pacienteSeleccionado?.nroDocumento,
                  pacienteTelefono: pacienteSeleccionado?.telefono,
                  pacienteGenero: pacienteSeleccionado?.genero,
                  lugarNombre: lugarSeleccionado?.nombre,
                  lugarDireccion: lugarSeleccionado?.direccion,
                  detalle: detalleController.text.trim(),
                  fechaInicio: fechaInicio!,
                  duracionMinutos: servicioSeleccionado?.duracionMinutos,
                );
                if (accion == null) return;
                accionFormulario = accion;
              } else if (cita.estado == CitasEstado.rechazada.value) {
                final confirmar = await confirmarAccionSimple(
                  titulo: 'Confirmar envío',
                  mensaje:
                      'Se enviarán los cambios de la cita rechazada para nueva revisión.',
                  accion: 'Confirmar',
                );
                if (!confirmar) return;
                accionFormulario = 'ENVIAR';
              }
              if (!context.mounted) return;
              Navigator.pop(modalContext, true);
            },
            body: buildFormularioCompleto(),
          );
        },
      );
    },
  );

  serviciosDebounce?.cancel();
  pacientesDebounce?.cancel();
  medicosDebounce?.cancel();
  lugaresDebounce?.cancel();
  if (result != true) return;

  final detalle = detalleController.text.trim();
  final medicoId = (medicoIdSeleccionado ?? '').trim();
  final pacienteId = (pacienteSeleccionado?.id ?? '').trim();
  final lugarId = (lugarSeleccionado?.id ?? '').trim();

  if (cita == null) {
    final accion = accionFormulario ?? 'GUARDAR';
    final response = await service.crearCita({
      'accion': accion,
      'detalle': detalle,
      'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
      if (medicoId.isNotEmpty) 'idPersonal': medicoId,
      if (pacienteSeleccionado != null) 'idPaciente': pacienteSeleccionado?.id,
      if (lugarId.isNotEmpty) 'idLugar': lugarId,
      'tipoCita': tipoCita,
      if (servicioSeleccionado != null) 'idServicio': servicioSeleccionado!.id,
    });
    final ok = await handleResponseError(response, 'No se pudo crear la cita.');
    if (!ok) return;

    showSnackBar(
      messengerKey,
      accion == 'GUARDAR'
          ? 'Cita guardada en borrador'
          : 'Cita enviada al calendario',
      state: StatusSnackBar.success,
      colorText: theme.white,
    );
    await cargarCitasCalendario();
    if (currentTabIndex == 2) {
      await cargarCitasListado(page: 1);
    }
    return;
  }

  final estadoActual = cita.estado;
  final estadoSeleccionado = estado;
  final cambioDetalle = detalle != cita.detalle;
  final cambioFecha = fechaInicio != cita.fechaInicio;
  final cambioMedico = medicoId != cita.medicoId;
  final cambioPaciente = pacienteId != (cita.pacienteId ?? '');
  final cambioTipoCita = tipoCita != (cita.tipoCita ?? '');
  final cambioLugar = lugarId != (cita.lugarId ?? '');
  final cambioServicio = servicioSeleccionado?.id != (cita.servicioId ?? '');

  if (estadoActual == CitasEstado.borrador.value) {
    final updates = <String, dynamic>{};
    if (cambioDetalle) updates['detalle'] = detalle;
    if (cambioMedico) updates['idPersonal'] = medicoId;
    if (cambioPaciente) {
      updates['idPaciente'] = pacienteId.isEmpty ? null : pacienteId;
    }
    if (cambioTipoCita) updates['tipoCita'] = tipoCita;
    if (cambioLugar) {
      updates['idLugar'] = lugarId.isEmpty ? null : lugarId;
    }
    if (cambioServicio) {
      updates['idServicio'] = servicioSeleccionado?.id;
    }
    if (cambioFecha) {
      updates['fechaInicio'] = fechaInicio!.toUtc().toIso8601String();
    }

    if (updates.isNotEmpty) {
      final ok = await handleResponseError(
        await service.editarBorradorCita(cita.id, updates),
        'No se pudo actualizar la cita borrador.',
      );
      if (!ok) return;
    }

    if (accionFormulario == 'ENVIAR') {
      final ok = await handleResponseError(
        await service.enviarCita(cita.id, idPersonal: medicoId),
        'No se pudo enviar la cita.',
      );
      if (!ok) return;
    }
  } else if (estadoActual == CitasEstado.rechazada.value) {
    final updates = <String, dynamic>{};
    if (cambioDetalle) updates['detalle'] = detalle;
    if (cambioMedico) updates['idPersonal'] = medicoId;
    if (cambioPaciente) {
      updates['idPaciente'] = pacienteId.isEmpty ? null : pacienteId;
    }
    if (cambioTipoCita) updates['tipoCita'] = tipoCita;
    if (cambioLugar) {
      updates['idLugar'] = lugarId.isEmpty ? null : lugarId;
    }
    if (cambioServicio) {
      updates['idServicio'] = servicioSeleccionado?.id;
    }
    if (cambioFecha) {
      updates['fechaInicio'] = fechaInicio!.toUtc().toIso8601String();
    }

    final ok = await handleResponseError(
      await service.enviarCita(cita.id, idPersonal: medicoId, body: updates),
      'No se pudo enviar la cita.',
    );
    if (!ok) return;
  } else if (estadoActual == CitasEstado.solicitada.value) {
    if (cambioMedico ||
        cambioPaciente ||
        cambioTipoCita ||
        cambioServicio ||
        cambioLugar) {
      showSnackBar(
        messengerKey,
        'En SOLICITADA solo puedes ajustar hora y detalle.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }
    if (!puedeGestionarSolicitada(cita)) {
      showSnackBar(
        messengerKey,
        'Solo el profesional asignado o el administrador pueden gestionar una cita solicitada.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }

    final ajuste = <String, dynamic>{};
    if (cambioDetalle) ajuste['detalle'] = detalle;
    if (cambioFecha) {
      ajuste['fechaInicio'] = fechaInicio!.toUtc().toIso8601String();
    }

    if (estadoSeleccionado == null || estadoSeleccionado == estadoActual) {
      if (ajuste.isNotEmpty) {
        showSnackBar(
          messengerKey,
          'En SOLICITADA debes confirmar o rechazar para aplicar cambios.',
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
      }
      return;
    }

    if (estadoSeleccionado == CitasEstado.cancelada.value) {
      showSnackBar(
        messengerKey,
        'Una cita solicitada no puede cancelarse directamente.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }

    if (estadoSeleccionado == CitasEstado.programada.value) {
      final ok = await handleResponseError(
        await service.confirmarCita(cita.id, body: ajuste),
        'No se pudo confirmar la cita.',
      );
      if (!ok) return;
    } else if (estadoSeleccionado == CitasEstado.rechazada.value) {
      final motivo = await solicitarMotivoRechazo();
      if (motivo == null) return;
      final ok = await handleResponseError(
        await service.rechazarCita(cita.id, motivoRechazo: motivo),
        'No se pudo rechazar la cita.',
      );
      if (!ok) return;
    } else {
      showSnackBar(
        messengerKey,
        'En SOLICITADA solo puedes confirmar o rechazar.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }
  } else if (estadoActual == CitasEstado.programada.value) {
    if (cambioDetalle ||
        cambioMedico ||
        cambioPaciente ||
        cambioTipoCita ||
        cambioServicio ||
        cambioLugar) {
      showSnackBar(
        messengerKey,
        'La cita programada no es editable.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }
    if (estadoSeleccionado == CitasEstado.cancelada.value) {
      final ok = await handleResponseError(
        await service.cancelarCita(cita.id),
        'No se pudo cancelar la cita.',
      );
      if (!ok) return;
    } else if (cambioFecha) {
      final ok = await handleResponseError(
        await service.reprogramarCita(cita.id, {
          'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
          'tipoCita': tipoCita,
          if (servicioSeleccionado != null)
            'idServicio': servicioSeleccionado!.id,
        }),
        'No se pudo reprogramar la cita.',
      );
      if (!ok) return;
    } else if (estadoSeleccionado != null &&
        estadoSeleccionado != estadoActual) {
      showSnackBar(
        messengerKey,
        'En PROGRAMADA solo puedes cancelar o reprogramar.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }
  } else if (estadoActual == CitasEstado.cancelada.value || estadoActual == CitasEstado.noAsistio.value) {
    if (cambioDetalle ||
        cambioMedico ||
        cambioPaciente ||
        cambioTipoCita ||
        cambioServicio ||
        (estadoSeleccionado != null && estadoSeleccionado != estadoActual)) {
      showSnackBar(
        messengerKey,
        'En este estado solo está permitida la reprogramación.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }
    if (cambioFecha) {
      final ok = await handleResponseError(
        await service.reprogramarCita(cita.id, {
          'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
          'tipoCita': tipoCita,
          if (servicioSeleccionado != null)
            'idServicio': servicioSeleccionado!.id,
        }),
        'No se pudo reprogramar la cita.',
      );
      if (!ok) return;
    } else {
      showSnackBar(
        messengerKey,
        'En este estado solo está permitida la reprogramación.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }
  } else {
    showSnackBar(
      messengerKey,
      'La cita no es editable en su estado actual.',
      state: StatusSnackBar.error,
      colorText: theme.white,
    );
    return;
  }

  await cargarCitasCalendario();
  if (currentTabIndex == 2) {
    await cargarCitasListado();
  }
}
