import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:control_ventas_movil/src/ui/common/drop_down/drop_down.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_service.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_store.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FormControl extends StatefulWidget {
  const FormControl({super.key});

  @override
  State<FormControl> createState() => _FormControl();
}

class _FormControl extends State<FormControl> {
  final GlobalKey<FormState> _scaffoldingFormKey = GlobalKey<FormState>();
  final GlobalKey<DropdownButton2State> dropKey =
      GlobalKey<DropdownButton2State>();
  final GlobalKey<DropdownButton2State> dropKeyHorario =
      GlobalKey<DropdownButton2State>();

  late ControlService service;
  List<String> estaciones = [];
  bool cargandoEstaciones = true;

  @override
  void initState() {
    service = ControlService('', context);
    service.fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final store = context.watch<ControlStore>();
    final estaciones = store.estaciones;
    final horarios = store.horarios;

    return Column(
      children: [
        Form(
            key: _scaffoldingFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selecciona una estación de servicio'),
                const SizedBox(height: 4),
                DropDown(
                  width: MediaQuery.of(context).size.width,
                  label: 'EESS Asignadas al regimiento',
                  requiredData: true,
                  dropKey: dropKey,
                  items: estaciones.map((estacion) {
                    return {
                      'id': estacion.id,
                      'label': estacion.nombre,
                    };
                  }).toList(),
                  onChange: (value) {
                    store.estacionSeleccionada = value;
                  },
                  validate: (value, alias) => service
                      .validateData(context, value, alias, required: true),
                ),
                const SizedBox(height: 16),
                const Text('Selecciona un horario'),
                const SizedBox(height: 4),
                DropDown(
                  width: MediaQuery.of(context).size.width,
                  label: 'Horarios',
                  requiredData: true,
                  dropKey: dropKeyHorario,
                  items: horarios.map((horario) {
                    return {
                      'id': horario.id,
                      'label':
                          '${horario.nombre}:${horario.horaInicio}-${horario.horaFin}',
                    };
                  }).toList(),
                  onChange: (value) {
                    store.horarioSeleccionado = value;
                  },
                  validate: (value, alias) => service
                      .validateData(context, value, alias, required: true),
                ),
                const SizedBox(height: 16),
                SimpleButton(
                    title: 'Iniciar control',
                    background: theme.primary700,
                    textColor: theme.white,
                    onTap: () {
                      if (service.validateForm(_scaffoldingFormKey)) {
                        service.iniciarControl(context);
                      }
                    }),
              ],
            ))
      ],
    );
  }
}
