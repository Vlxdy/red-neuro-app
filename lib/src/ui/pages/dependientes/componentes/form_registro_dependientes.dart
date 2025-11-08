import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/models/dependiente.dart';
import 'package:alimenta_app/src/ui/common/buttons/simple_button.dart';
import 'package:alimenta_app/src/ui/common/components/bottom_navigation.dart';
import 'package:alimenta_app/src/ui/common/components/custom_title.dart';
import 'package:alimenta_app/src/ui/common/snackbar/snackbar.dart';
import 'package:alimenta_app/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:alimenta_app/src/ui/pages/dependientes/screens/dependientes.dart';
import 'package:alimenta_app/src/ui/pages/dependientes/services/dependientes.dart';
import 'package:alimenta_app/src/ui/pages/dependientes/stores/registro_dependientes_store.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:provider/provider.dart';

class FormDependientes extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final Dependiente? dependienteEditar;

  const FormDependientes({
    super.key,
    required this.titulo,
    required this.descripcion,
    this.dependienteEditar,
  });

  @override
  State<FormDependientes> createState() => _FormDependientes();
}

class _FormDependientes extends State<FormDependientes> {
  late DependientesService service;
  final RegistroDependientesStore store = RegistroDependientesStore.instance;
  final TextEditingController nombreDependiente = TextEditingController();
  final TextEditingController codigoDependiente = TextEditingController();
  List<ObjetoId> areasDependiente = [];

  @override
  void initState() {
    super.initState();
    service = DependientesService('', context);
    nombreDependiente.text = widget.dependienteEditar?.nombre ?? '';
    codigoDependiente.text = widget.dependienteEditar?.codigo ?? '';
  }

  void _guardarDependiente() {
    if (nombreDependiente.text.trim().isNotEmpty) {
      final nombre = nombreDependiente.text.trim();
      final codigo = codigoDependiente.text.trim();
      final areas = areasDependiente;

      service.registrarDependiente(
        context,
        nombre,
        codigo,
        areas,
        widget.dependienteEditar?.id,
      );
    } else {
      showSnackBar(
        dependientesMessenger,
        'Debe ingresar nombre, al menos 2 puntos de ruta y 3 del Dependiente',
        state: StatusSnackBar.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Consumer<RegistroDependientesStore>(
      builder: (context, store, child) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTitle(
                  title: widget.titulo,
                  icon: Icons.map,
                  color: theme.secondary,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(widget.descripcion, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: nombreDependiente,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Dependiente',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: codigoDependiente,
                    decoration: const InputDecoration(
                      labelText: 'Codigo del Dependiente',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MultiSelectDialogField<String>(
                    items: RegistroAreasStore.instance.listaAreas
                        .where((a) => a.estado == 'ACTIVO')
                        .map((a) => MultiSelectItem(a.id, a.nombre))
                        .toList(),
                    title: const Text("Áreas permitidas"),
                    initialValue: [
                      ...?widget.dependienteEditar?.dependienteArea
                          .map((area) => area.id)
                    ],
                    selectedColor: Colors.blue,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey),
                    ),
                    buttonText: const Text("Seleccionar Áreas"),
                    onConfirm: (values) {
                      areasDependiente = values.map((idArea) {
                        return ObjetoId(id: idArea);
                      }).toList();
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigation(
            button1: SimpleButton(
              title: 'Guardar',
              onTap: _guardarDependiente,
            ),
            button2: SimpleButton(
              title: 'Cancelar',
              onTap: () => Navigator.pop(context),
              outlined: true,
              background: theme.secondary,
              textColor: theme.black,
            ),
          ),
        );
      },
    );
  }
}
