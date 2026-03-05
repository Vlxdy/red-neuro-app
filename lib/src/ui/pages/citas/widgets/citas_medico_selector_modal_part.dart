part of '../citas_page.dart';

extension _CitasPageMedicoSelectorModalPart on _CitasPageState {
  Future<void> _abrirSelectorMedicoFiltro() async {
    final List<PersonalMedico> medicosDisponibles = [];
    bool medicosLoading = false;
    bool medicosHasMore = true;
    int medicosPage = 1;
    int total = 0;
    String medicosFiltro = '';
    Timer? medicosDebounce;

    Future<void> cargarMedicos({
      required bool reset,
      VoidCallback? onUpdated,
    }) async {
      if (medicosLoading) return;
      medicosLoading = true;
      onUpdated?.call();
      if (reset) {
        medicosPage = 1;
        medicosHasMore = true;
        total = 0;
        medicosDisponibles.clear();
      }
      final result = await _service.obtenerPersonalMedico(
        page: medicosPage,
        limit: 10,
        filtro: medicosFiltro,
      );
      if (!mounted) return;
      if (result.items.isNotEmpty) {
        medicosDisponibles.addAll(result.items);
      }
      total = result.total;
      medicosHasMore = medicosDisponibles.length < result.total;
      medicosPage += 1;
      medicosLoading = false;
      onUpdated?.call();
    }

    await cargarMedicos(reset: true);
    if (!mounted) return;

    final seleccionado = await showModalBottomSheet<PersonalMedico>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final searchController = TextEditingController(text: medicosFiltro);
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'Selecciona personal asignado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar personal asignado',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
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
                          if (medicosDisponibles.isEmpty && medicosLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (medicosDisponibles.isEmpty) {
                            return const Center(child: Text('Sin resultados'));
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
                                      icon: const Icon(Icons.expand_more),
                                      label: const Text('Cargar más'),
                                    ),
                                  ),
                                );
                              }
                              final option = medicosDisponibles[index];
                              return ListTile(
                                title: Text(option.nombreCompleto),
                                subtitle:
                                    (option.nroDocumento?.isNotEmpty ?? false)
                                    ? Text('Documento: ${option.nroDocumento}')
                                    : null,
                                onTap: () => Navigator.pop(context, option),
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

    medicosDebounce?.cancel();
    if (seleccionado == null) return;
    setState(() {
      _medicoFiltro = seleccionado.id;
      _medicoFiltroNombre = seleccionado.nombreCompleto;
      _medicoFiltroController.text = seleccionado.nombreCompleto;
    });
  }


}
