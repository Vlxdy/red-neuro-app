import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/models/plan_nutricional.dart';
import 'package:red_neuro_app/src/ui/pages/plan_nutricional/services/plan_nutricional_service.dart';
import 'package:red_neuro_app/src/ui/pages/plan_nutricional/stores/plan_nutricional_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlanNutricionalPage extends StatefulWidget {
  const PlanNutricionalPage({super.key});

  @override
  State<PlanNutricionalPage> createState() => _PlanNutricionalPageState();
}

class _PlanNutricionalPageState extends State<PlanNutricionalPage>
    with AutomaticKeepAliveClientMixin {
  late PlanNutricionalService _service;
  late TextEditingController _comentarioController;
  late ScrollController _scrollController;
  final _theme = ThemeController.instance;
  bool _fabExpanded = false;
  String? _planIdEnfocado;

  final _ordenIngestas = const [
    'DESAYUNO',
    'MEDIA_MANIANA',
    'ALMUERZO',
    'MEDIA_TARDE',
    'CENA',
  ];

  final Map<String, String> _labelsIngestas = const {
    'DESAYUNO': 'Desayuno',
    'MEDIA_MANIANA': 'Media mañana',
    'ALMUERZO': 'Almuerzo',
    'MEDIA_TARDE': 'Media tarde',
    'CENA': 'Cena',
  };

  final Map<String, GlobalKey> _sectionKeys = {};

  Uri? _construirUrlImagen(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      final base = Uri.parse(Constantes.apiUrl);
      return base.resolve(path);
    } catch (_) {
      return Uri.tryParse(path);
    }
  }

  @override
  void initState() {
    super.initState();
    _comentarioController = TextEditingController();
    _scrollController = ScrollController();
    _service = PlanNutricionalService('', context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.initialize();
    });
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFabMenu([bool? value]) {
    setState(() {
      _fabExpanded = value ?? !_fabExpanded;
    });
  }

  Future<void> _seleccionarFecha(PlanNutricionalStore store) async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: store.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (nuevaFecha != null) {
      if (_fabExpanded) {
        _toggleFabMenu(false);
      }
      setState(() {
        _planIdEnfocado = null;
      });
      await _service.cargarPlanParaFecha(nuevaFecha);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat.yMMMMEEEEd('es').format(fecha);
  }

  String? _determinarIngestaActual(Iterable<String> tiposDisponibles) {
    if (tiposDisponibles.isEmpty) return null;
    final hora = TimeOfDay.now().hour;
    String sugerido;
    if (hora < 10) {
      sugerido = 'DESAYUNO';
    } else if (hora < 12) {
      sugerido = 'MEDIA_MANIANA';
    } else if (hora < 15) {
      sugerido = 'ALMUERZO';
    } else if (hora < 18) {
      sugerido = 'MEDIA_TARDE';
    } else {
      sugerido = 'CENA';
    }
    if (tiposDisponibles.contains(sugerido)) {
      return sugerido;
    }
    for (final tipo in _ordenIngestas) {
      if (tiposDisponibles.contains(tipo)) {
        return tipo;
      }
    }
    return tiposDisponibles.first;
  }

  void _enfocarIngesta(Map<String, List<PlanAlimento>> grupos, String planId) {
    if (!mounted || grupos.isEmpty) return;
    if (_planIdEnfocado == planId) return;
    final tiposDisponibles = grupos.keys;
    final tipoObjetivo = _determinarIngestaActual(tiposDisponibles);
    if (tipoObjetivo == null) return;
    final key = _sectionKeys[tipoObjetivo];
    if (key?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
    _planIdEnfocado = planId;
  }

  Widget _buildEstadoCarga(PlanNutricionalStore store) {
    if (store.loadingPlan) {
      return const Center(child: CircularProgressIndicator());
    }
    if (store.errorMessage != null && store.errorMessage!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            store.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _theme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    if (!store.planEncontrado || store.plan == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No se encontró un plan nutricional para la fecha seleccionada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _theme.neutral,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMacroRow(String label, MacroValue objetivo, MacroValue plan) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _theme.fontColor,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objetivo: ${objetivo.gramos.toStringAsFixed(1)} g (${(objetivo.porcentaje * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(color: _theme.neutral, fontSize: 12),
                ),
                Text(
                  'Plan: ${plan.gramos.toStringAsFixed(1)} g (${(plan.porcentaje * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(color: _theme.fontColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(PlanNutricional plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Resumen del día',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _theme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Calorías objetivo: ${plan.caloriasObjetivo.toStringAsFixed(0)} kcal',
          style: TextStyle(
            fontSize: 16,
            color: _theme.fontColor,
          ),
        ),
        if (plan.recomendaciones.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Recomendaciones',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _theme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.recomendaciones,
            style: TextStyle(color: _theme.fontColor),
          ),
        ],
      ],
    );
  }

  Widget _buildMacros(PlanNutricional plan) {
    final macros = plan.distribucionMacronutrientes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Distribución de macronutrientes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _theme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _buildMacroRow('Carbohidratos', macros.objetivo.carbohidratos,
            macros.planGenerado.carbohidratos),
        _buildMacroRow('Proteínas', macros.objetivo.proteinas,
            macros.planGenerado.proteinas),
        _buildMacroRow(
            'Grasas', macros.objetivo.grasas, macros.planGenerado.grasas),
      ],
    );
  }

  Widget _buildDistribucionCalorica(PlanNutricional plan) {
    final distribucion = plan.distribucionCalorica;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Distribución calórica',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _theme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ..._ordenIngestas.map((tipo) {
          final objetivo = distribucion.buscarObjetivoPorTipo(tipo);
          final planGenerado = distribucion.buscarPlanPorTipo(tipo);
          if (objetivo == null && planGenerado == null) {
            return const SizedBox.shrink();
          }
          final nombre = _labelsIngestas[tipo] ?? tipo;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _theme.fontColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (objetivo != null)
                        Text(
                          'Objetivo: ${objetivo.calorias.toStringAsFixed(0)} kcal (${(objetivo.porcentaje * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(color: _theme.neutral, fontSize: 12),
                        ),
                      if (planGenerado != null)
                        Text(
                          'Plan: ${planGenerado.calorias.toStringAsFixed(0)} kcal (${(planGenerado.porcentaje * 100).toStringAsFixed(1)}%)',
                          style:
                              TextStyle(color: _theme.fontColor, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAlimentoTile(
    PlanNutricionalStore store,
    PlanAlimento alimento,
  ) {
    final imagenUrl = _construirUrlImagen(alimento.urlImage);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: store.estadoAlimento(alimento.id),
              onChanged: (value) {
                if (value != null) {
                  _service.actualizarEstadoAlimento(alimento.id, value);
                }
              },
              activeColor: _theme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _mostrarDetalleAlimento(alimento, imagenUrl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alimento.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _theme.fontColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alimento.cantidad.toStringAsFixed(2)} ${alimento.unidadMedida.toLowerCase()} · ${alimento.calorias.toStringAsFixed(0)} kcal',
                      style: TextStyle(color: _theme.neutral, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'C:${alimento.carbohidratos.toStringAsFixed(1)}g  P:${alimento.proteinas.toStringAsFixed(1)}g  G:${alimento.grasa.toStringAsFixed(1)}g',
                      style: TextStyle(color: _theme.neutral, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca para ver más detalles',
                      style: TextStyle(color: _theme.secondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imagenUrl != null
                  ? Image.network(
                      imagenUrl.toString(),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.restaurant,
                        color: _theme.neutral,
                      ),
                    )
                  : Icon(
                      Icons.restaurant,
                      color: _theme.neutral,
                      size: 32,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaAlimentos(
      PlanNutricionalStore store, PlanNutricional plan) {
    final grupos = plan.groupAlimentosPorTipo(orden: _ordenIngestas);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || plan.id.isEmpty) return;
      _enfocarIngesta(grupos, plan.id);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grupos.entries.map((entry) {
        final label = _labelsIngestas[entry.key] ?? entry.key;
        final sectionKey =
            _sectionKeys.putIfAbsent(entry.key, () => GlobalKey());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              key: sectionKey,
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _theme.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value.length} alimento${entry.value.length == 1 ? '' : 's'}',
                    style: TextStyle(color: _theme.neutral, fontSize: 12),
                  ),
                ],
              ),
            ),
            ...entry.value
                .map((alimento) => _buildAlimentoTile(store, alimento)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildComentario(PlanNutricionalStore store) {
    if (_comentarioController.text != store.comentario) {
      _comentarioController.value = TextEditingValue(
        text: store.comentario,
        selection: TextSelection.collapsed(offset: store.comentario.length),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comentario del día',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _theme.primary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentarioController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Registra observaciones o comentarios generales.',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _service.actualizarComentario(value);
              },
            ),
            if (store.savingSeguimiento) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _theme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Guardando cambios...',
                    style: TextStyle(color: _theme.neutral, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldMessenger(
      key: planNutricionalMessenger,
      child: Scaffold(
        backgroundColor: _theme.background,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Consumer<PlanNutricionalStore>(
          builder: (context, store, _) {
            final plan = store.plan;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_fabExpanded && plan != null && store.planEncontrado) ...[
                  FloatingActionButton.extended(
                    heroTag: 'fab_resumen',
                    onPressed: () {
                      _toggleFabMenu(false);
                      _mostrarModalInformacion(
                        title: 'Resumen del día',
                        child: _buildResumen(plan),
                      );
                    },
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Resumen'),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'fab_macros',
                    onPressed: () {
                      _toggleFabMenu(false);
                      _mostrarModalInformacion(
                        title: 'Distribución de macronutrientes',
                        child: _buildMacros(plan),
                      );
                    },
                    icon: const Icon(Icons.pie_chart),
                    label: const Text('Macronutrientes'),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'fab_calorias',
                    onPressed: () {
                      _toggleFabMenu(false);
                      _mostrarModalInformacion(
                        title: 'Distribución calórica',
                        child: _buildDistribucionCalorica(plan),
                      );
                    },
                    icon: const Icon(Icons.local_fire_department_outlined),
                    label: const Text('Calorías'),
                  ),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  heroTag: 'fab_menu',
                  onPressed: () => _toggleFabMenu(),
                  backgroundColor: _theme.primary,
                  child: Icon(
                    _fabExpanded ? Icons.close : Icons.menu,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
        body: SafeArea(
          child: Consumer<PlanNutricionalStore>(
            builder: (context, store, _) {
              final estado = _buildEstadoCarga(store);
              final plan = store.plan;
              return RefreshIndicator(
                onRefresh: () =>
                    _service.cargarPlanParaFecha(store.selectedDate),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan nutricional',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _theme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatearFecha(store.selectedDate),
                                  style: TextStyle(color: _theme.neutral),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _seleccionarFecha(store),
                            icon: Icon(
                              Icons.calendar_today,
                              color: _theme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (store.loadingPlan ||
                          store.errorMessage != null ||
                          !store.planEncontrado)
                        estado,
                      if (plan != null && store.planEncontrado) ...[
                        _buildListaAlimentos(store, plan),
                        const SizedBox(height: 16),
                        _buildComentario(store),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _mostrarDetalleAlimento(
    PlanAlimento alimento,
    Uri? imagenUrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _theme.neutral.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (imagenUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imagenUrl.toString(),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: _theme.background,
                        alignment: Alignment.center,
                        child: Icon(Icons.restaurant, color: _theme.neutral),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: _theme.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.restaurant,
                      color: _theme.neutral,
                      size: 48,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  alimento.nombre,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _theme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alimento.categoria,
                  style: TextStyle(color: _theme.neutral, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildDetalleDato('Porción sugerida',
                    '${alimento.cantidadReferencial.toStringAsFixed(2)} ${alimento.unidadMedida.toLowerCase()}'),
                const SizedBox(height: 8),
                _buildDetalleDato('Cantidad en el plan',
                    '${alimento.cantidad.toStringAsFixed(2)} ${alimento.unidadMedida.toLowerCase()}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildChipInfo(
                        'Calorías',
                        '${alimento.calorias.toStringAsFixed(0)} kcal',
                        Icons.local_fire_department_outlined),
                    _buildChipInfo(
                        'Carbohidratos',
                        '${alimento.carbohidratos.toStringAsFixed(1)} g',
                        Icons.grain_outlined),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildChipInfo(
                        'Proteínas',
                        '${alimento.proteinas.toStringAsFixed(1)} g',
                        Icons.set_meal_outlined),
                    _buildChipInfo(
                        'Grasas',
                        '${alimento.grasa.toStringAsFixed(1)} g',
                        Icons.water_drop_outlined),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalInformacion(
      {required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _theme.neutral.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _theme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetalleDato(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _theme.fontColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: _theme.neutral),
        ),
      ],
    );
  }

  Widget _buildChipInfo(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _theme.primary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _theme.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _theme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: _theme.fontColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
