import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/enums.dart';
import 'package:control_ventas_movil/src/ui/common/drop_down/drop_down.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/date_input.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/text_input.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_service.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_store.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FormVolumenesTanques extends StatefulWidget {
  const FormVolumenesTanques({super.key});

  @override
  State<FormVolumenesTanques> createState() => _FormVolumenesTanques();
}

class _FormVolumenesTanques extends State<FormVolumenesTanques> {
  final GlobalKey<DropdownButton2State> dropKey =
      GlobalKey<DropdownButton2State>();
  final GlobalKey<DropdownButton2State> dropKeyHorario =
      GlobalKey<DropdownButton2State>();

  final TextEditingController dateController = TextEditingController();
  late ControlService service;
  List<String> estaciones = [];
  List<TipoMedicion> tiposMedicion = TipoMedicion.values;
  bool cargandoEstaciones = true;
  TimeOfDay? selectedTime;
  String? _tipoSeleccionado;
  List<Tanque> tanques = [
    Tanque(nombre: "Tanque 1", codigo: "T1"),
    Tanque(nombre: "Tanque 2", codigo: "T2"),
    Tanque(nombre: "Tanque 3", codigo: "T3"),
  ];

  List<TextEditingController> horaControllers = [];
  List<TextEditingController> combustibleControllers = [];
  List<TextEditingController> volumenControllers = [];

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // service = ControlService(); // Asegúrate de inicializarlo si es necesario
    for (var _ in tanques) {
      horaControllers.add(TextEditingController());
      combustibleControllers.add(TextEditingController());
      volumenControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in [
      ...horaControllers,
      ...combustibleControllers,
      ...volumenControllers
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _guardarFormulario() {
    Map<String, dynamic> datosFormulario = {
      "tipoMedicion": _tipoSeleccionado,
      "tanques": List.generate(tanques.length, (index) {
        return {
          "nombre": tanques[index].nombre,
          "codigo": tanques[index].codigo,
          "hora": horaControllers[index].text,
          "tipoCombustible": combustibleControllers[index].text,
          "volumen": volumenControllers[index].text,
        };
      })
    };
    print(datosFormulario); // Aquí podrías enviar los datos al backend
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final store = context.watch<ControlStore>();
    final horarios = store.horarios;

    return Scaffold(
      appBar: AppBar(title: Text("Registro de Medición")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Stepper(
                  type: StepperType.horizontal,
                physics:
                    ClampingScrollPhysics(), // Asegura que el desplazamiento funcione bien
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep <= tanques.length) {
                    setState(() => _currentStep++);
                  } else {
                    _guardarFormulario();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
                steps: [
                  Step(
                    title: const Text("Seleccionar tipo de medición"),
                    content: DropDown(
                      width: MediaQuery.of(context).size.width,
                      label: 'Tipo de medición',
                      requiredData: true,
                      dropKey: dropKey,
                      items: tiposMedicion.map((tipo) {
                        return {
                          'id': tipo.info,
                          'label': tipo.info,
                        };
                      }).toList(),
                      onChange: (value) {
                        setState(() {
                          _tipoSeleccionado = value;
                        });
                      },
                      validate: (value, alias) => service
                          .validateData(context, value, alias, required: true),
                    ),
                    isActive: _currentStep >= 0,
                  ),
                  // Pasos dinámicos para cada tanque
                  ...tanques.asMap().entries.map(
                    (entry) {
                      int index = entry.key;
                      Tanque tanque = entry.value;

                      return Step(
                        title: Text("Registrar ${tanque.nombre}"),
                        content: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CustomTimePicker(
                                title: 'Hora de Registro',
                                controller: horaControllers[index],
                                placeholder: 'Seleccionar hora',
                                requiredData: true,
                                onTap: () {
                                  print("Date field tapped");
                                },
                                validate: (value, alias) {
                                  if (value == null || value.isEmpty) {
                                    return '$alias es obligatorio';
                                  }
                                  return '';
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CustomTextInput(
                                requiredData: true,
                                controller: volumenControllers[index],
                                title: 'Usuario',
                                onChange: (value) => () {},
                                validate: (value, alias) =>
                                    service.validateData(
                                  context,
                                  value,
                                  alias,
                                ),
                              ),
                            ),
                          ],
                        ),
                        isActive: _currentStep >= index + 1,
                      );
                    },
                  ),

                  // Paso final: Confirmación
                  Step(
                    title: Text("Confirmar"),
                    content: ElevatedButton(
                      onPressed: _guardarFormulario,
                      child: Text("Guardar"),
                    ),
                    isActive: _currentStep == tanques.length + 1,
                  ),
                ],
                controlsBuilder:
                    (BuildContext context, ControlsDetails details) {
                  return Row(
                    children: [
                      if (_currentStep > 0)
                        ElevatedButton(
                          onPressed: details.onStepCancel,
                          child: const Text("Anterior"),
                        ),
                      if (_currentStep <= tanques.length)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: const Text("Siguiente"),
                        ),
                      if (_currentStep > tanques.length)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: const Text("Guardar"),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Tanque {
  final String nombre;
  final String codigo;
  Tanque({required this.nombre, required this.codigo});
}
