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
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setStateModal) {
                return Padding(
                  padding: const EdgeInsets.all(16),
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
                      SizedBox(
                        height: 320,
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
                              estadoFiltro: _estadoFiltro,
                              onEstadoChanged: (value) {
                                setState(() => _estadoFiltro = value);
                                setStateModal(() {});
                              },
                              mostrarFiltroMedico: widget.mostrarFiltroMedico,
                              medicoController: _medicoFiltroController,
                              medicoIdSeleccionado: _medicoFiltro,
                              bloquearFiltroMedico:
                                  _bloquearFiltroMedicoPorSoloMisCitas,
                              etiquetaMedicoBloqueado: _nombreMedicoActual,
                              onTapMedico: () async {
                                await _abrirSelectorMedicoFiltro();
                                setStateModal(() {});
                              },
                              onClearMedico: () {
                                setState(() {
                                  _medicoFiltro = null;
                                  _medicoFiltroNombre = null;
                                  _medicoFiltroController.clear();
                                });
                                setStateModal(() {});
                              },
                              fechaInicio: _fechaInicioFiltro,
                              fechaFin: _fechaFinFiltro,
                              formatter: _dateFormat,
                              onTapFechaInicio: () =>
                                  _seleccionarFecha(inicio: true),
                              onTapFechaFin: () =>
                                  _seleccionarFecha(inicio: false),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_bloquearFiltroMedicoPorSoloMisCitas)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _theme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _theme.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: _theme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Modo activo: solo mis citas • $_nombreMedicoActual',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: _theme.primary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
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
                    ],
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
