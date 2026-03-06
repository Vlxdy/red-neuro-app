part of '../citas_page.dart';

extension _CitasPageFiltrosModalPart on _CitasPageState {
  Future<void> _abrirFiltrosModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setStateModal) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Filtros',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                          ),
                          child: Scrollbar(
                            controller: _filtersScrollController,
                            child: SingleChildScrollView(
                              controller: _filtersScrollController,
                              child: CitasFiltersFields(
                                isCompact: true,
                                buscarController: _buscarController,
                                onBuscarChanged: (value) {
                                  setState(() => _buscarTexto = value);
                                  setStateModal(() {});
                                },
                                estadoController: _estadoFiltroController,
                                onTapEstado: () async {
                                  await _abrirSelectorEstadoFiltro();
                                  setStateModal(() {});
                                },
                                mostrarFiltroMedico: widget.mostrarFiltroMedico,
                                personalAsignadoController:
                                    _medicoFiltroController,
                                personalAsignadoIdSeleccionado: _medicoFiltro,
                                bloquearFiltroPersonalAsignado:
                                    _bloquearFiltroMedicoPorSoloMisCitas,
                                etiquetaPersonalAsignadoBloqueado:
                                    _nombreMedicoActual,
                                onTapPersonalAsignado: () async {
                                  await _abrirSelectorMedicoFiltro();
                                  setStateModal(() {});
                                },
                                onClearPersonalAsignado: () {
                                  setState(() {
                                    _medicoFiltro = null;
                                    _medicoFiltroNombre = null;
                                    _medicoFiltroController.clear();
                                  });
                                  setStateModal(() {});
                                },
                                lugarController: _lugarFiltroController,
                                lugarIdSeleccionado: _lugarFiltro,
                                onTapLugar: () async {
                                  await _abrirSelectorLugarFiltro();
                                  setStateModal(() {});
                                },
                                onClearLugar: () {
                                  setState(() {
                                    _lugarFiltro = null;
                                    _lugarFiltroNombre = null;
                                    _lugarFiltroController.clear();
                                  });
                                  setStateModal(() {});
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SafeArea(
                          top: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _limpiarFiltros();
                                  setStateModal(() {});
                                },
                                child: const Text('Limpiar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _aplicarFiltros();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.sync),
                                label: const Text('Aplicar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
