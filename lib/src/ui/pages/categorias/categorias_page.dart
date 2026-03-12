import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/categoria.dart';
import 'package:red_neuro_app/src/ui/common/components/tray_ui_helpers.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:red_neuro_app/src/ui/common/form_stepper/step_form_dialog_layout.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/categorias/categorias_service.dart';

final GlobalKey<ScaffoldMessengerState> categoriasMessenger =
    GlobalKey<ScaffoldMessengerState>();

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> with FormController {
  final _theme = ThemeController.instance;
  late final CategoriasService _service;
  List<Categoria> _categorias = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = CategoriasService(context);
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _loading = true);
    final result = await _service.obtenerCategorias();
    if (!mounted) return;
    setState(() {
      _categorias = result.categorias;
      _loading = false;
    });
    if (result.status != StatusNetwork.connected) {
      showSnackBar(categoriasMessenger, result.message, state: StatusSnackBar.error);
    }
  }

  Future<void> _abrirFormulario({Categoria? categoria}) async {
    final form = GlobalKey<FormState>();
    final nombre = TextEditingController(text: categoria?.nombre ?? '');
    final descripcion = TextEditingController(text: categoria?.descripcion ?? '');
    final colorHex = TextEditingController(text: categoria?.colorHex ?? '#ef4444');
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Form(
            key: form,
            child: StepFormDialogLayout(
              title: categoria == null ? 'Nueva categoría' : 'Editar categoría',
              totalSteps: 1,
              currentStep: 0,
              isSubmitting: submitting,
              onClose: () => Navigator.pop(ctx),
              nextLabel: categoria == null ? 'Crear' : 'Guardar',
              onNext: () async {
                if (!form.currentState!.validate()) return;
                setStateDialog(() => submitting = true);
                final body = {
                  'nombre': nombre.text.trim(),
                  if (descripcion.text.trim().isNotEmpty) 'descripcion': descripcion.text.trim(),
                  if (colorHex.text.trim().isNotEmpty) 'colorHex': colorHex.text.trim(),
                };
                final response = categoria == null
                    ? await _service.crearCategoria(body)
                    : await _service.actualizarCategoria(categoria.id, body);
                if (!mounted) return;
                if (response.status == StatusNetwork.connected) {
                  Navigator.pop(ctx);
                  _cargarCategorias();
                  return;
                }
                setStateDialog(() => submitting = false);
              },
              stepContent: Column(children: [
                CustomTextInput(
                  title: 'Nombre',
                  controller: nombre,
                  requiredData: true,
                  validate: (v, a) => validateData(context, v, a, required: true),
                ),
                const SizedBox(height: 12),
                CustomTextInput(title: 'Descripción', controller: descripcion, lines: 3),
                const SizedBox(height: 12),
                CustomTextInput(title: 'Color HEX', controller: colorHex),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePage(
      showEnvironmentBanner: false,
      page: ScaffoldMessenger(
        key: categoriasMessenger,
        child: Scaffold(
          appBar: TrayModuleHeader(
            titulo: 'Categorías',
            subtitulo: 'Administra el catálogo de categorías para servicios.',
            actions: [
              IconButton(onPressed: _cargarCategorias, icon: const Icon(Icons.refresh)),
              IconButton(onPressed: () => _abrirFormulario(), icon: const Icon(Icons.add)),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : CustomDesktopDataTable(
                  titulo: 'Gestión de categorías',
                  descripcion: 'Consulta y administra categorías.',
                  columnas: [
                    CriterioOrdenType(nombre: 'Nombre'),
                    CriterioOrdenType(nombre: 'Descripción'),
                    CriterioOrdenType(nombre: 'Color'),
                    CriterioOrdenType(nombre: 'Estado'),
                    CriterioOrdenType(nombre: 'Acciones'),
                  ],
                  contenidoTabla: _categorias
                      .map((categoria) => [
                            Text(categoria.nombre),
                            Text(categoria.descripcion ?? '-'),
                            Text(categoria.colorHex ?? '-'),
                            TrayStatusBadge(status: categoria.estado, activeColor: _theme.success),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _abrirFormulario(categoria: categoria),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await _service.cambiarEstadoCategoria(categoria.id);
                                    _cargarCategorias();
                                  },
                                  icon: Icon(categoria.estado.toUpperCase() == 'ACTIVO' ? Icons.toggle_off : Icons.toggle_on),
                                ),
                              ],
                            ),
                          ])
                      .toList(),
                ),
        ),
      ),
    );
  }
}
