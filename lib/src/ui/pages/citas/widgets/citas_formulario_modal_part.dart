part of '../citas_page.dart';

extension _CitasPageFormularioModalPart on _CitasPageState {
  Future<void> _abrirFormulario({CitaMedica? cita, DateTime? fechaBase}) async {
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
    final baseSeleccionada = fechaBase ?? _selectedDay;
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
        fechaInicio ??= _resolveDefaultStartTime(baseSeleccionada);
      }
    }
    String? estado = cita?.estado;
    String tipoCita = (cita?.tipoCita?.isNotEmpty ?? false)
        ? cita!.tipoCita!
        : 'CONSULTA';
    Especialidad? especialidadSeleccionada;
    Servicio? servicioSeleccionado;
    if (cita?.especialidadId != null && cita!.especialidadId!.isNotEmpty) {
      especialidadSeleccionada = Especialidad(
        id: cita.especialidadId!,
        nombre:
            cita.especialidadNombre ?? 'Especialidad ${cita.especialidadId}',
        descripcion: null,
        estado: 'ACTIVO',
        colorHex: cita.especialidadColorHex ?? '#64748b',
        estudios: const [],
      );
    }
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
        especialidades: const [],
      );
    }
    final especialidadController = TextEditingController(
      text: especialidadSeleccionada?.nombre ?? '',
    );
    final servicioController = TextEditingController(
      text: servicioSeleccionado?.nombre ?? '',
    );
    final lugarController = TextEditingController(
      text: lugarSeleccionado?.nombre ?? '',
    );
    final List<Especialidad> especialidadesDisponibles = [];
    final List<Servicio> serviciosDisponibles = [];
    final List<Paciente> pacientesDisponibles = [];
    final List<PersonalMedico> medicosDisponibles = [];
    final List<Lugar> lugaresDisponibles = [];
    bool especialidadesLoading = false;
    bool serviciosLoading = false;
    bool pacientesLoading = false;
    bool medicosLoading = false;
    bool lugaresLoading = false;
    bool especialidadesHasMore = true;
    bool serviciosHasMore = true;
    bool pacientesHasMore = true;
    bool medicosHasMore = true;
    int especialidadesPage = 1;
    int serviciosPage = 1;
    int pacientesPage = 1;
    int medicosPage = 1;
    int lugaresPage = 1;
    String especialidadesFiltro = '';
    String serviciosFiltro = '';
    String pacientesFiltro = '';
    String medicosFiltro = '';
    String lugaresFiltro = '';
    Timer? especialidadesDebounce;
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
            Future<void> cargarEspecialidades({
              bool reset = false,
              void Function()? onUpdated,
            }) async {
              if (especialidadesLoading) return;
              setStateDialog(() => especialidadesLoading = true);
              if (reset) {
                especialidadesPage = 1;
                especialidadesHasMore = true;
                especialidadesDisponibles.clear();
              }
              final result = await _service.obtenerEspecialidades(
                page: especialidadesPage,
                limit: 10,
                filtro: especialidadesFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  especialidadesDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  especialidadesDisponibles.addAll(result.items);
                }
                especialidadesHasMore =
                    especialidadesDisponibles.length < result.total;
                especialidadesPage += 1;
                especialidadesLoading = false;
              });
              onUpdated?.call();
            }

            Future<void> cargarServicios({
              bool reset = false,
              void Function()? onUpdated,
            }) async {
              if (serviciosLoading) return;
              final especialidadId = especialidadSeleccionada?.id ?? '';
              setStateDialog(() => serviciosLoading = true);
              if (reset) {
                serviciosPage = 1;
                serviciosHasMore = true;
                serviciosDisponibles.clear();
              }
              final result = especialidadId.isNotEmpty
                  ? await _service.obtenerServiciosPorEspecialidad(
                      especialidadId: especialidadId,
                      tipo: tipoCita,
                      page: serviciosPage,
                      limit: 10,
                      filtro: serviciosFiltro,
                    )
                  : await _service.obtenerServicios(
                      tipo: tipoCita,
                      page: serviciosPage,
                      limit: 10,
                      filtro: serviciosFiltro,
                    );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  serviciosDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  serviciosDisponibles.addAll(result.items);
                }
                serviciosHasMore = serviciosDisponibles.length < result.total;
                serviciosPage += 1;
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
              final result = await _service.obtenerPacientes(
                page: pacientesPage,
                limit: 10,
                filtro: pacientesFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  pacientesDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  pacientesDisponibles.addAll(result.items);
                }
                pacientesHasMore = pacientesDisponibles.length < result.total;
                pacientesPage += 1;
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
              final result = await _service.obtenerPersonalMedico(
                page: medicosPage,
                limit: 10,
                filtro: medicosFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  medicosDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  medicosDisponibles.addAll(result.items);
                }
                medicosHasMore = medicosDisponibles.length < result.total;
                medicosPage += 1;
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
              final result = await _service.obtenerLugares(
                page: lugaresPage,
                limit: 10,
                filtro: lugaresFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  lugaresDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  lugaresDisponibles.addAll(result.items);
                }
                lugaresPage += 1;
                lugaresLoading = false;
              });
            }

            if (!inicializado) {
              inicializado = true;
              unawaited(cargarEspecialidades(reset: true));
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Selecciona un paciente',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                                      return const Center(
                                        child: Text('Sin resultados'),
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
                                                    : () =>
                                                          cargar(reset: false),
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
                                              (option
                                                      .nroDocumento
                                                      ?.isNotEmpty ??
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Selecciona personal asignado',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                                      return const Center(
                                        child: Text('Sin resultados'),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          medicosDisponibles.length +
                                          (medicosHasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                                medicosDisponibles.length &&
                                            medicosHasMore) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: medicosLoading
                                                    ? null
                                                    : () =>
                                                          cargar(reset: false),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label: const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option =
                                            medicosDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombreCompleto),
                                          subtitle:
                                              (option
                                                      .nroDocumento
                                                      ?.isNotEmpty ??
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

            Future<void> abrirSelectorEspecialidad() async {
              if (especialidadesDisponibles.isEmpty && !especialidadesLoading) {
                await cargarEspecialidades(reset: true);
                if (!context.mounted) return;
              }
              final seleccion = await showModalBottomSheet<Especialidad>(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  final searchController = TextEditingController(
                    text: especialidadesFiltro,
                  );
                  return StatefulBuilder(
                    builder: (context, setStateSheet) {
                      Future<void> cargar({required bool reset}) async {
                        await cargarEspecialidades(
                          reset: reset,
                          onUpdated: () => setStateSheet(() {}),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Selecciona una especialidad',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: CustomTextInput(
                                  controller: searchController,
                                  title: 'Buscar especialidad',
                                  onChange: (value) {
                                    especialidadesFiltro = value;
                                    especialidadesDebounce?.cancel();
                                    especialidadesDebounce = Timer(
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
                                    if (especialidadesDisponibles.isEmpty &&
                                        especialidadesLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (especialidadesDisponibles.isEmpty) {
                                      return const Center(
                                        child: Text('Sin resultados'),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          especialidadesDisponibles.length +
                                          (especialidadesHasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                                especialidadesDisponibles
                                                    .length &&
                                            especialidadesHasMore) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: especialidadesLoading
                                                    ? null
                                                    : () =>
                                                          cargar(reset: false),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label: const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option =
                                            especialidadesDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombre),
                                          subtitle: option.descripcion != null
                                              ? Text(option.descripcion!)
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
                      );
                    },
                  );
                },
              );
              if (seleccion == null) return;
              setStateDialog(() {
                especialidadSeleccionada = seleccion;
                especialidadController.text = seleccion.nombre;
                tipoCita = tipoCita.isNotEmpty ? tipoCita : 'CONSULTA';
                servicioSeleccionado = null;
                servicioController.clear();
                serviciosFiltro = '';
                serviciosDisponibles.clear();
                serviciosHasMore = true;
                serviciosPage = 1;
              });
              unawaited(cargarServicios(reset: true));
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Selecciona un lugar',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
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
                              const SizedBox(height: 12),
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
                                      return const Center(
                                        child: Text('Sin resultados'),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: lugaresDisponibles.length,
                                      itemBuilder: (context, index) {
                                        final option =
                                            lugaresDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombre),
                                          subtitle:
                                              option.direccion.trim().isNotEmpty
                                              ? Text(option.direccion)
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Selecciona un servicio',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
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
                              const SizedBox(height: 12),
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
                                      return const Center(
                                        child: Text('Sin resultados'),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          serviciosDisponibles.length +
                                          (serviciosHasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                                serviciosDisponibles.length &&
                                            serviciosHasMore) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: serviciosLoading
                                                    ? null
                                                    : () =>
                                                          cargar(reset: false),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label: const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option =
                                            serviciosDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombre),
                                          subtitle:
                                              option.descripcion.isNotEmpty
                                              ? Text(option.descripcion)
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
              servicioFieldKey.currentState?.didChange(seleccion);
              if (intentoEnvio) {
                servicioFieldKey.currentState?.validate();
              }
            }

            Future<Paciente?> abrirNuevoPaciente() async {
              final formKeyPaciente = GlobalKey<FormState>();
              final nombresController = TextEditingController();
              final primerApellidoController = TextEditingController();
              final segundoApellidoController = TextEditingController();
              final nroDocumentoController = TextEditingController();
              final fechaNacimientoController = TextEditingController();
              final telefonoController = TextEditingController();
              final observacionController = TextEditingController();
              DateTime? fechaNacimiento;
              String? generoSeleccionado;
              bool guardando = false;

              return showDialog<Paciente>(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setStatePaciente) {
                      Future<void> seleccionarFechaNacimiento() async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked == null) return;
                        setStatePaciente(() {
                          fechaNacimiento = picked;
                          fechaNacimientoController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        });
                      }

                      Future<void> guardarPaciente() async {
                        if (!formKeyPaciente.currentState!.validate()) return;
                        setStatePaciente(() => guardando = true);
                        final body = <String, dynamic>{
                          'nombres': nombresController.text.trim(),
                          if (primerApellidoController.text.trim().isNotEmpty)
                            'primerApellido': primerApellidoController.text
                                .trim(),
                          if (segundoApellidoController.text.trim().isNotEmpty)
                            'segundoApellido': segundoApellidoController.text
                                .trim(),
                          if (nroDocumentoController.text.trim().isNotEmpty)
                            'nroDocumento': nroDocumentoController.text.trim(),
                          if (fechaNacimiento != null)
                            'fechaNacimiento': DateFormat(
                              'yyyy-MM-dd',
                            ).format(fechaNacimiento!),
                          if (telefonoController.text.trim().isNotEmpty)
                            'telefono': telefonoController.text.trim(),
                          if (generoSeleccionado?.trim().isNotEmpty ?? false)
                            'genero': generoSeleccionado,
                          if (observacionController.text.trim().isNotEmpty)
                            'observacion': observacionController.text.trim(),
                        };
                        final response = await _service.crearPaciente(body);
                        if (!context.mounted) return;
                        final ok = await _handleResponseError(
                          response,
                          'No se pudo registrar el paciente.',
                        );
                        if (!context.mounted) return;
                        if (!ok) {
                          setStatePaciente(() => guardando = false);
                          return;
                        }
                        final raw =
                            response.data['datos'] ??
                            response.data['data'] ??
                            response.data;
                        if (raw is Map<String, dynamic>) {
                          final paciente = Paciente.fromJson(raw);
                          showSnackBar(
                            citasMessenger,
                            'Paciente creado correctamente',
                            state: StatusSnackBar.success,
                            colorText: _theme.white,
                          );
                          Navigator.pop(context, paciente);
                          return;
                        }
                        Navigator.pop(context);
                      }

                      return AlertDialog(
                        title: const Text('Nuevo paciente'),
                        content: SingleChildScrollView(
                          child: Form(
                            key: formKeyPaciente,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomTextInput(
                                  controller: nombresController,
                                  title: 'Nombres',
                                  requiredData: true,
                                  validate: (value, alias) =>
                                      _validarRequerido(value, alias),
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  controller: primerApellidoController,
                                  title: 'Primer apellido',
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  controller: segundoApellidoController,
                                  title: 'Segundo apellido',
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  controller: nroDocumentoController,
                                  title: 'Número de documento',
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: fechaNacimientoController,
                                  readOnly: true,
                                  decoration: CustomTextInputStyles.decoration(
                                    label: 'Fecha de nacimiento',
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.event),
                                      onPressed: seleccionarFechaNacimiento,
                                    ),
                                  ),
                                  onTap: seleccionarFechaNacimiento,
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  controller: telefonoController,
                                  title: 'Teléfono',
                                  onlyNumbers: true,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: generoSeleccionado,
                                  decoration: CustomTextInputStyles.decoration(
                                    label: 'Género',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'F',
                                      child: Text('Femenino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'M',
                                      child: Text('Masculino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'O',
                                      child: Text('Otro'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setStatePaciente(
                                      () => generoSeleccionado = value,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  controller: observacionController,
                                  title: 'Observaciones',
                                  lines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: guardando
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: guardando ? null : guardarPaciente,
                            child: guardando
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Guardar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
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
                        final edad = _calcularEdadPaciente(
                          paciente.fechaNacimiento,
                        );
                        final nacimiento = _formatearFechaPaciente(
                          paciente.fechaNacimiento,
                        );
                        final genero = _formatearGenero(paciente.genero).trim();

                        final detallesPrioritarios = <({
                          IconData icon,
                          String label,
                          String value,
                        })>[
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

                        final detallesExtras = <({
                          IconData icon,
                          String label,
                          String value,
                        })>[
                          ...detallesPrioritarios.skip(3),
                          if ((paciente.observacion ?? '').trim().isNotEmpty)
                            (
                              icon: Icons.sticky_note_2_outlined,
                              label: 'Observaciones',
                              value: paciente.observacion!.trim(),
                            ),
                        ];

                        final detallesVisibles =
                            detallesPrioritarios.take(3).toList();

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
                                color: _theme.primary.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _theme.primary.withValues(alpha: .2),
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
                                                color: _theme.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
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
                                                    color: _theme.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
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
                                ? _theme.white
                                : _theme.grey,
                          ),
                        ),
                        selectedColor: _theme.primary,
                        backgroundColor: _theme.grey.withValues(alpha: .12),
                        side: BorderSide(
                          color: tipoCita == 'CONSULTA'
                              ? _theme.primary
                              : _theme.grey.withValues(alpha: .35),
                        ),
                        selected: tipoCita == 'CONSULTA',
                        onSelected: (_) {
                          setStateDialog(() {
                            tipoCita = 'CONSULTA';
                            servicioSeleccionado = null;
                            servicioController.clear();
                            serviciosDisponibles.clear();
                            serviciosHasMore = true;
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
                                ? _theme.white
                                : _theme.grey,
                          ),
                        ),
                        selectedColor: _theme.primary,
                        backgroundColor: _theme.grey.withValues(alpha: .12),
                        side: BorderSide(
                          color: tipoCita == 'ESTUDIO'
                              ? _theme.primary
                              : _theme.grey.withValues(alpha: .35),
                        ),
                        selected: tipoCita == 'ESTUDIO',
                        onSelected: (_) {
                          setStateDialog(() {
                            tipoCita = 'ESTUDIO';
                            servicioSeleccionado = null;
                            servicioController.clear();
                            serviciosDisponibles.clear();
                            serviciosHasMore = true;
                            serviciosPage = 1;
                            unawaited(cargarServicios(reset: true));
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FormField<Especialidad>(
                    builder: (state) {
                      return CitasAutocompleteSelectorField(
                        controller: especialidadController,
                        labelText: 'Especialidad',
                        hintText: 'Selecciona una especialidad',
                        errorText: state.errorText,
                        onClear: especialidadSeleccionada == null
                            ? null
                            : () {
                                setStateDialog(() {
                                  especialidadSeleccionada = null;
                                  especialidadController.clear();
                                  servicioSeleccionado = null;
                                  servicioController.clear();
                                  serviciosDisponibles.clear();
                                  serviciosHasMore = true;
                                  serviciosPage = 1;
                                });
                                state.didChange(null);
                                unawaited(cargarServicios(reset: true));
                              },
                        onTap: () async {
                          await abrirSelectorEspecialidad();
                          state.didChange(especialidadSeleccionada);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
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
                          formatter: _dateFormat,
                          onTap: updateFechaInicioFecha,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FechaSelector(
                          label: 'Hora',
                          requiredData: true,
                          value: fechaInicio,
                          formatter: _timeFormat,
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
                      (cita.estado == 'SOLICITADA' ||
                          cita.estado == 'CONFIRMADA'))
                    const SizedBox(height: 12),
                  if (cita != null &&
                      (cita.estado == 'SOLICITADA' ||
                          cita.estado == 'CONFIRMADA'))
                    DropdownButtonFormField<String?>(
                      initialValue: estado,
                      decoration: CustomTextInputStyles.decoration(
                        label: 'Estado',
                      ),
                      items:
                          {
                            cita.estado,
                            if (cita.estado == 'SOLICITADA') ...[
                              'CONFIRMADA',
                              'RECHAZADA',
                            ],
                            if (cita.estado == 'CONFIRMADA') 'CANCELADA',
                          }.map((estadoItem) {
                            final requierePermiso =
                                estadoItem == 'CONFIRMADA' ||
                                estadoItem == 'RECHAZADA';
                            final habilitado =
                                !requierePermiso ||
                                _puedeGestionarSolicitada(cita) ||
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
                      color: _theme.background,
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
                          autovalidateMode: intentoEnvio
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cita == null
                                            ? 'Registro de cita'
                                            : 'Actualizar cita',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                    if (cita?.estado == 'RECHAZADA')
                                      IconButton(
                                        tooltip: 'Ver historial',
                                        onPressed: () =>
                                            _mostrarHistorialCita(cita!),
                                        icon: const Icon(
                                          Icons.history_outlined,
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: 'Cerrar',
                                      onPressed: () =>
                                          Navigator.pop(modalContext, false),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                buildFormularioCompleto(),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.pop(modalContext, false),
                                        child: const Text('Cancelar'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () async {
                                          setStateDialog(
                                            () => intentoEnvio = true,
                                          );
                                          if (!validarFormulario()) {
                                            return;
                                          }
                                          if (cita == null ||
                                              cita.estado == 'BORRADOR') {
                                            final accion =
                                                await _confirmarAccionCita(
                                                  esNueva: cita == null,
                                                  tipoCita: _formatearTipoCita(
                                                    tipoCita,
                                                  ),
                                                  pacienteNombre:
                                                      pacienteSeleccionado
                                                          ?.nombreCompleto,
                                                  especialidadNombre:
                                                      especialidadSeleccionada
                                                          ?.nombre,
                                                  servicioNombre:
                                                      servicioSeleccionado
                                                          ?.nombre ??
                                                      'Sin servicio',
                                                  medicoNombre: medicoController
                                                      .text
                                                      .trim(),
                                                  pacienteDocumento:
                                                      pacienteSeleccionado
                                                          ?.nroDocumento,
                                                  pacienteTelefono:
                                                      pacienteSeleccionado
                                                          ?.telefono,
                                                  pacienteGenero:
                                                      pacienteSeleccionado
                                                          ?.genero,
                                                  lugarNombre:
                                                      lugarSeleccionado?.nombre,
                                                  lugarDireccion:
                                                      lugarSeleccionado
                                                          ?.direccion,
                                                  detalle: detalleController
                                                      .text
                                                      .trim(),
                                                  fechaInicio: fechaInicio!,
                                                  duracionMinutos:
                                                      servicioSeleccionado
                                                          ?.duracionMinutos,
                                                );
                                            if (accion == null) return;
                                            accionFormulario = accion;
                                          } else if (cita.estado ==
                                              'RECHAZADA') {
                                            final confirmar =
                                                await _confirmarAccionSimple(
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
                                        child: Text(
                                          cita == null
                                              ? 'Crear cita'
                                              : (cita.estado == 'BORRADOR'
                                                    ? 'Guardar'
                                                    : cita.estado ==
                                                          'RECHAZADA'
                                                    ? 'Confirmar'
                                                    : 'Actualizar cita'),
                                        ),
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
          },
        );
      },
    );

    especialidadesDebounce?.cancel();
    serviciosDebounce?.cancel();
    pacientesDebounce?.cancel();
    medicosDebounce?.cancel();
    lugaresDebounce?.cancel();
    if (result != true) return;

    final detalle = detalleController.text.trim();
    final medicoId = (medicoIdSeleccionado ?? '').trim();
    final pacienteId = (pacienteSeleccionado?.id ?? '').trim();
    final especialidadId = especialidadSeleccionada?.id ?? '';
    final lugarId = (lugarSeleccionado?.id ?? '').trim();

    if (cita == null) {
      final accion = accionFormulario ?? 'GUARDAR';
      final response = await _service.crearCita({
        'accion': accion,
        'detalle': detalle,
        'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
        if (medicoId.isNotEmpty) 'idPersonal': medicoId,
        if (pacienteSeleccionado != null)
          'idPaciente': pacienteSeleccionado?.id,
        if (especialidadId.isNotEmpty) 'idEspecialidad': especialidadId,
        if (lugarId.isNotEmpty) 'idLugar': lugarId,
        'tipoCita': tipoCita,
        if (servicioSeleccionado != null)
          'idServicio': servicioSeleccionado!.id,
      });
      final ok = await _handleResponseError(
        response,
        'No se pudo crear la cita.',
      );
      if (!ok) return;

      showSnackBar(
        citasMessenger,
        accion == 'GUARDAR'
            ? 'Cita guardada en borrador'
            : 'Cita enviada al calendario',
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) {
        await _cargarCitasListado(page: 1);
      }
      return;
    }

    final estadoActual = cita.estado;
    final estadoSeleccionado = estado;
    final cambioDetalle = detalle != cita.detalle;
    final cambioFecha = fechaInicio != cita.fechaInicio;
    final cambioMedico = medicoId != cita.medicoId;
    final cambioPaciente = pacienteId != (cita.pacienteId ?? '');
    final cambioEspecialidad = especialidadId != (cita.especialidadId ?? '');
    final cambioTipoCita = tipoCita != (cita.tipoCita ?? '');
    final cambioLugar = lugarId != (cita.lugarId ?? '');
    final cambioServicio = servicioSeleccionado?.id != (cita.servicioId ?? '');

    if (estadoActual == 'BORRADOR') {
      final updates = <String, dynamic>{};
      if (cambioDetalle) updates['detalle'] = detalle;
      if (cambioMedico) updates['idPersonal'] = medicoId;
      if (cambioPaciente) {
        updates['idPaciente'] = pacienteId.isEmpty ? null : pacienteId;
      }
      if (cambioEspecialidad) {
        updates['idEspecialidad'] = especialidadId;
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
        final ok = await _handleResponseError(
          await _service.editarBorradorCita(cita.id, updates),
          'No se pudo actualizar la cita borrador.',
        );
        if (!ok) return;
      }

      if (accionFormulario == 'ENVIAR') {
        final ok = await _handleResponseError(
          await _service.enviarCita(cita.id, idPersonal: medicoId),
          'No se pudo enviar la cita.',
        );
        if (!ok) return;
      }
    } else if (estadoActual == 'RECHAZADA') {
      final updates = <String, dynamic>{};
      if (cambioDetalle) updates['detalle'] = detalle;
      if (cambioMedico) updates['idPersonal'] = medicoId;
      if (cambioPaciente) {
        updates['idPaciente'] = pacienteId.isEmpty ? null : pacienteId;
      }
      if (cambioEspecialidad) {
        updates['idEspecialidad'] = especialidadId;
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

      final ok = await _handleResponseError(
        await _service.enviarCita(
          cita.id,
          idPersonal: medicoId,
          body: updates,
        ),
        'No se pudo enviar la cita.',
      );
      if (!ok) return;
    } else if (estadoActual == 'SOLICITADA') {
      if (cambioMedico ||
          cambioPaciente ||
          cambioEspecialidad ||
          cambioTipoCita ||
          cambioServicio ||
          cambioLugar) {
        showSnackBar(
          citasMessenger,
          'En SOLICITADA solo puedes ajustar hora y detalle.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
      if (!_puedeGestionarSolicitada(cita)) {
        showSnackBar(
          citasMessenger,
          'Solo el profesional asignado o el administrador pueden gestionar una cita solicitada.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
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
            citasMessenger,
            'En SOLICITADA debes confirmar o rechazar para aplicar cambios.',
            state: StatusSnackBar.error,
            colorText: _theme.white,
          );
        }
        return;
      }

      if (estadoSeleccionado == 'CANCELADA') {
        showSnackBar(
          citasMessenger,
          'Una cita solicitada no puede cancelarse directamente.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }

      if (estadoSeleccionado == 'CONFIRMADA') {
        final ok = await _handleResponseError(
          await _service.confirmarCita(cita.id, body: ajuste),
          'No se pudo confirmar la cita.',
        );
        if (!ok) return;
      } else if (estadoSeleccionado == 'RECHAZADA') {
        final motivo = await _solicitarMotivoRechazo();
        if (motivo == null) return;
        final ok = await _handleResponseError(
          await _service.rechazarCita(cita.id, motivoRechazo: motivo),
          'No se pudo rechazar la cita.',
        );
        if (!ok) return;
      } else {
        showSnackBar(
          citasMessenger,
          'En SOLICITADA solo puedes confirmar o rechazar.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
    } else if (estadoActual == 'CONFIRMADA') {
      if (cambioDetalle ||
          cambioMedico ||
          cambioPaciente ||
          cambioEspecialidad ||
          cambioTipoCita ||
          cambioServicio ||
          cambioLugar) {
        showSnackBar(
          citasMessenger,
          'La cita confirmada no es editable.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
      if (estadoSeleccionado == 'CANCELADA') {
        final ok = await _handleResponseError(
          await _service.cancelarCita(cita.id),
          'No se pudo cancelar la cita.',
        );
        if (!ok) return;
      } else if (cambioFecha) {
        final ok = await _handleResponseError(
          await _service.reprogramarCita(cita.id, {
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
          citasMessenger,
          'En CONFIRMADA solo puedes cancelar o reprogramar.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
    } else if (estadoActual == 'CANCELADA' || estadoActual == 'NO_ASISTIO') {
      if (cambioDetalle ||
          cambioMedico ||
          cambioPaciente ||
          cambioEspecialidad ||
          cambioTipoCita ||
          cambioServicio ||
          (estadoSeleccionado != null && estadoSeleccionado != estadoActual)) {
        showSnackBar(
          citasMessenger,
          'En este estado solo está permitida la reprogramación.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
      if (cambioFecha) {
        final ok = await _handleResponseError(
          await _service.reprogramarCita(cita.id, {
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
          citasMessenger,
          'En este estado solo está permitida la reprogramación.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
    } else {
      showSnackBar(
        citasMessenger,
        'La cita no es editable en su estado actual.',
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
      return;
    }

    await _cargarCitasCalendario();
    if (_currentTabIndex == 2) {
      await _cargarCitasListado();
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'BORRADOR':
        return _theme.grey.withValues(alpha: 0.75);
      case 'SOLICITADA':
        return _theme.accent500;
      case 'CONFIRMADA':
        return _theme.primary;
      case 'COMPLETADA':
        return _theme.success;
      case 'NO_ASISTIO':
        return _theme.warning;
      case 'CANCELADA':
        return _theme.error;
      case 'RECHAZADA':
        return _theme.accent500;
      case 'REPROGRAMADA':
        return const Color(0xFF8E7CC3);
      default:
        return _theme.grey.withValues(alpha: 0.6);
    }
  }

  String _normalizarRol(String rol) {
    final normalized = rol.toUpperCase();
    switch (normalized) {
      case 'ADMIN':
        return 'ADMINISTRADOR';
      case 'MEDICO':
      case 'PERSONAL_MEDICO':
      case 'SUPERVISOR':
        return 'PERSONAL_SALUD';
      default:
        return normalized;
    }
  }

  bool _tieneRol(String rol) {
    final normalized = _normalizarRol(rol);
    final perfil = Auth.instance.profile;
    final roles = <String>{};
    if ((perfil.rol ?? '').trim().isNotEmpty) {
      roles.add(_normalizarRol(perfil.rol!));
    }
    roles.addAll(
      perfil.roles
          .map((rol) => _normalizarRol(rol.rol))
          .where((rol) => rol.trim().isNotEmpty),
    );
    return roles.contains(normalized);
  }

  bool _esAdministrador() => _tieneRol('ADMINISTRADOR');

  bool _esMedicoAsignado(CitaMedica cita) {
    final medicoId = cita.medicoId.trim();
    final idUsuarioRol = (Auth.instance.profile.idUsuarioRol ?? '').trim();
    if (medicoId.isEmpty || idUsuarioRol.isEmpty) return false;
    return medicoId == idUsuarioRol;
  }

  bool _puedeGestionarSolicitada(CitaMedica cita) {
    return _esMedicoAsignado(cita) || _esAdministrador();
  }

  String _formatoFechaHoraHistorial(DateTime? fecha) {
    if (fecha == null) return '--';
    return _dateTimeFormat.format(fecha);
  }

  String _tituloHistorial(HistorialCita item) {
    final rol = item.rolEjecutor.trim();
    final tieneCambios = item.detalleCambios.isNotEmpty;
    if (tieneCambios) return 'Actualización de cita';
    if (item.estadoAnterior.trim().isNotEmpty) return 'Cambio de estado';
    if (rol.isEmpty || RegExp(r'^\d+$').hasMatch(rol)) {
      return 'Registro de cita';
    }
    return 'Acción de $rol';
  }

  String _normalizarValorHistorial(String raw) {
    var value = raw.trim();
    if (value.startsWith('{') && value.endsWith('}')) {
      value = value.substring(1, value.length - 1);
    }
    value = value.replaceAll('undefined', '').replaceAll('null', '').trim();
    if (value.isEmpty) return '--';
    if (value == 'true') return 'Sí';
    if (value == 'false') return 'No';
    final isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}');
    if (isoPattern.hasMatch(value)) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return _dateTimeFormat.format(parsed.toLocal());
      }
    }
    return value;
  }

  String _formatearCambioId({
    required String label,
    required String before,
    required String after,
  }) {
    final antes = before == '--' ? '' : before;
    final despues = after == '--' ? '' : after;
    if (antes.isEmpty && despues.isNotEmpty) {
      return '$label asignado';
    }
    if (antes.isNotEmpty && despues.isEmpty) {
      return '$label removido';
    }
    return '$label actualizado';
  }

  String _formatearTipoCita(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'ESTUDIO') return 'Estudio';
    if (normalized == 'CONSULTA') return 'Consulta';
    return value;
  }

  String _formatearDetallePersona(HistorialDetallePersona detalle) {
    final nombre = detalle.nombreCompleto;
    final parts = <String>[
      if (nombre.trim().isNotEmpty) nombre,
      if ((detalle.nroDocumento ?? '').trim().isNotEmpty)
        detalle.nroDocumento!.trim(),
      if (detalle.especialidades.isNotEmpty) detalle.especialidades.join(', '),
    ];
    return parts.isEmpty ? '--' : parts.join(' · ');
  }

  String _formatearCambioPersona({
    required String label,
    required String beforeValue,
    required String afterValue,
    HistorialDetallePersona? beforeDetalle,
    HistorialDetallePersona? afterDetalle,
  }) {
    final antes = beforeDetalle != null
        ? _formatearDetallePersona(beforeDetalle)
        : beforeValue;
    final despues = afterDetalle != null
        ? _formatearDetallePersona(afterDetalle)
        : afterValue;
    final antesNormalizado = antes == '--' ? '' : antes;
    final despuesNormalizado = despues == '--' ? '' : despues;

    if (antesNormalizado.isEmpty && despuesNormalizado.isNotEmpty) {
      return '$label asignado: $despuesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isEmpty) {
      return '$label removido: $antesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isNotEmpty) {
      return '$label: $antesNormalizado → $despuesNormalizado';
    }
    return 'Actualización de $label';
  }

  String _formatearDetalleServicio(HistorialDetalleEstudio detalle) {
    final nombre = detalle.nombre.trim();
    return nombre.isNotEmpty ? nombre : '--';
  }

  String _formatearCambioServicio({
    required String label,
    required String beforeValue,
    required String afterValue,
    HistorialDetalleEstudio? beforeDetalle,
    HistorialDetalleEstudio? afterDetalle,
  }) {
    final antes = beforeDetalle != null
        ? _formatearDetalleServicio(beforeDetalle)
        : beforeValue;
    final despues = afterDetalle != null
        ? _formatearDetalleServicio(afterDetalle)
        : afterValue;
    final antesNormalizado = antes == '--' ? '' : antes;
    final despuesNormalizado = despues == '--' ? '' : despues;

    if (antesNormalizado.isEmpty && despuesNormalizado.isNotEmpty) {
      return '$label asignado: $despuesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isEmpty) {
      return '$label removido: $antesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isNotEmpty) {
      return '$label: $antesNormalizado → $despuesNormalizado';
    }
    return 'Actualización de $label';
  }

  String? _formatearDetalleCambioLegacy(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.contains('field:')) {
      return trimmed.contains('{') ? null : trimmed;
    }

    final fieldMatch = RegExp(r'field:\s*([a-zA-Z0-9_]+)').firstMatch(trimmed);
    final field = fieldMatch?.group(1) ?? '';
    if (field.isEmpty) return null;
    final esIdRelacionado = field.toLowerCase().endsWith('id');

    final labels = <String, String>{
      'fechaInicio': 'Fecha inicio',
      'fechaFin': 'Fecha fin',
      'detalle': 'Detalle',
      'estado': 'Estado',
      'tipoCita': 'Tipo de cita',
      'esEstudio': 'Tipo de cita',
      'idEspecialidad': 'Especialidad',
      'idPersonal': 'Personal asignado',
      'idPaciente': 'Paciente',
      'idConsultorio': 'Consultorio',
      'idLugar': 'Lugar',
      'idServicio': 'Servicio',
      'idEstudio': 'Servicio',
    };

    final label = labels[field] ?? field;
    final beforeMatch = RegExp(r'before:\s*([^,}]+)').firstMatch(trimmed);
    final afterMatch = RegExp(r'after:\s*([^,}]+)').firstMatch(trimmed);
    final beforeValue = beforeMatch != null
        ? _normalizarValorHistorial(beforeMatch.group(1)!)
        : '';
    final afterValue = afterMatch != null
        ? _normalizarValorHistorial(afterMatch.group(1)!)
        : '';

    if (esIdRelacionado) {
      return _formatearCambioId(
        label: label,
        before: beforeValue,
        after: afterValue,
      );
    }
    if (field == 'tipoCita') {
      return '$label: ${_formatearTipoCita(beforeValue)} → ${_formatearTipoCita(afterValue)}';
    }
    if (beforeValue.isNotEmpty && afterValue.isNotEmpty) {
      return '$label: $beforeValue → $afterValue';
    }
    return 'Actualización de $label';
  }

  String? _formatearDetalleCambio(HistorialCambio cambio) {
    if (cambio.rawDetalle != null) {
      return _formatearDetalleCambioLegacy(cambio.rawDetalle!);
    }
    final field = cambio.field.trim();
    if (field.isEmpty) return null;
    final esIdRelacionado = field.toLowerCase().endsWith('id');

    final labels = <String, String>{
      'fechaInicio': 'Fecha inicio',
      'fechaFin': 'Fecha fin',
      'detalle': 'Detalle',
      'estado': 'Estado',
      'tipoCita': 'Tipo de cita',
      'esEstudio': 'Tipo de cita',
      'idEspecialidad': 'Especialidad',
      'idPersonal': 'Personal asignado',
      'idPaciente': 'Paciente',
      'idConsultorio': 'Consultorio',
      'idLugar': 'Lugar',
      'idServicio': 'Servicio',
      'idEstudio': 'Servicio',
    };

    final label = labels[field] ?? field;
    final beforeValue = _normalizarValorHistorial(cambio.before ?? '');
    final afterValue = _normalizarValorHistorial(cambio.after ?? '');

    if (field == 'idPersonal' || field == 'idPaciente') {
      return _formatearCambioPersona(
        label: label,
        beforeValue: beforeValue,
        afterValue: afterValue,
        beforeDetalle: cambio.beforeDetalle,
        afterDetalle: cambio.afterDetalle,
      );
    }
    if (field == 'idServicio' || field == 'idEstudio') {
      return _formatearCambioServicio(
        label: label,
        beforeValue: beforeValue,
        afterValue: afterValue,
        beforeDetalle: cambio.beforeDetalleEstudio,
        afterDetalle: cambio.afterDetalleEstudio,
      );
    }
    if (esIdRelacionado) {
      return _formatearCambioId(
        label: label,
        before: beforeValue,
        after: afterValue,
      );
    }
    if (field == 'tipoCita') {
      return '$label: ${_formatearTipoCita(beforeValue)} → ${_formatearTipoCita(afterValue)}';
    }
    if (beforeValue.isNotEmpty && afterValue.isNotEmpty) {
      return '$label: $beforeValue → $afterValue';
    }
    return 'Actualización de $label';
  }

  DateTime _inicioDia(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _finDia(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }


}
