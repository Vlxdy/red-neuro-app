import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/enums.dart';
import 'package:control_ventas_movil/src/models/combustible.dart';
import 'package:control_ventas_movil/src/models/registro_meters.dart';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:control_ventas_movil/src/ui/common/drop_down/drop_down.dart';
import 'package:control_ventas_movil/src/ui/common/form_stepper/form_stepper.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/date_input.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/text_input.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_store.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques_service.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FormVolumenesTanques extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final List<VolumenTanque> tanques;
  final List<TipoMedicion> tiposMedicion;
  final List<Combustible> listaCombustibles;

  const FormVolumenesTanques({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.tanques,
    required this.tiposMedicion,
    required this.listaCombustibles,
  });

  @override
  State<FormVolumenesTanques> createState() => _FormVolumenesTanques();
}

class _FormVolumenesTanques extends State<FormVolumenesTanques> {
  late VolumenesTanquesService service;
  final GlobalKey<DropdownButton2State> dropKey =
      GlobalKey<DropdownButton2State>();
  final GlobalKey<DropdownButton2State> dropKeyHorario =
      GlobalKey<DropdownButton2State>();

  final TextEditingController dateController = TextEditingController();
  List<String> estaciones = [];

  bool cargandoEstaciones = true;
  TimeOfDay? selectedTime;
  String? _tipoSeleccionado;

  List<TextEditingController> horaControllers = [];
  List<TextEditingController> combustibleControllers = [];
  List<TextEditingController> volumenControllers = [];
  List<GlobalKey<DropdownButton2State>> dropKeys = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<DropdownButton2State> dropKeyTipoMedicion =
      GlobalKey<DropdownButton2State>();
  DropDownType? selectedTipoMedicion;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    service = VolumenesTanquesService('/mobile', context);
    for (var _ in widget.tanques) {
      horaControllers.add(TextEditingController());
      combustibleControllers.add(TextEditingController());
      volumenControllers.add(TextEditingController());
    }
    dropKeys = List.generate(widget.listaCombustibles.length,
        (_) => GlobalKey<DropdownButton2State>());
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
      "tanques": List.generate(widget.tanques.length, (index) {
        return {
          "nombre": widget.tanques[index].tanques?.nombre,
          "hora": horaControllers[index].text,
          "tipoCombustible": combustibleControllers[index].text,
          "volumen": volumenControllers[index].text,
        };
      })
    };
    service.registrarVolumenes(context, datosFormulario);
    // print(datosFormulario); // Aquí podrías enviar los datos al backend
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final store = context.watch<ControlStore>();

    return Scaffold(
      appBar: AppBar(title: Text("Registro de Medición")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.descripcion, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              DropDown(
                width: MediaQuery.of(context).size.width,
                label: 'Tipo de medición',
                requiredData: true,
                dropKey: dropKey,
                items: widget.tiposMedicion.map((tipo) {
                  return {
                    'id': tipo.info,
                    'label': tipo.info,
                  };
                }).toList(),
                onChange: (String? value) {
                  setState(() {
                    _tipoSeleccionado = value;
                  });
                },
                // validate: (value, alias) =>
                //     service.validateData(context, value, alias, required: true),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (widget.tanques.length > 1) ...[
                      SizedBox(
                          height: 72,
                          child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: FormStepper(
                                longitud: widget.tanques.length,
                                currentStep: _currentStep,
                                activeColor: theme.secondary,
                              ))),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        child: VolumenTanqueWidget(
                          listaCombustibles: widget.listaCombustibles,
                          combustibleController:
                              combustibleControllers[_currentStep],
                          horaController: horaControllers[_currentStep],
                          volumenController: volumenControllers[_currentStep],
                          dropKey: dropKeys[_currentStep],
                          volumenTanque: widget.tanques[_currentStep],
                          onChange: (String? value) {
                            setState(() {
                              combustibleControllers[_currentStep].text =
                                  value ?? '';
                            });
                          },
                          step: _currentStep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep--;
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(_currentStep == 0 ? 'Cancelar' : 'Anterior'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_currentStep < widget.tanques.length - 1) {
                  setState(() => _currentStep++);
                } else {
                  _guardarFormulario();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
              ),
              child: Text(
                _currentStep == widget.tanques.length - 1
                    ? 'Finalizar registro'
                    : 'Siguiente',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Tanque {
  final String nombre;
  final String codigo;
  Tanque({required this.nombre, required this.codigo});
}

class VolumenTanqueWidget extends StatefulWidget {
  final VolumenTanque volumenTanque;
  final List<Combustible> listaCombustibles;
  final TextEditingController horaController;
  final TextEditingController combustibleController;
  final TextEditingController volumenController;
  final GlobalKey<DropdownButton2State> dropKey;
  final Function(String?)? onChange;
  final int step;

  const VolumenTanqueWidget({
    super.key,
    required this.volumenTanque,
    required this.listaCombustibles,
    required this.horaController,
    required this.combustibleController,
    required this.volumenController,
    required this.dropKey,
    this.onChange,
    required this.step,
  });

  @override
  VolumenTanqueWidgetState createState() => VolumenTanqueWidgetState();
}

class VolumenTanqueWidgetState extends State<VolumenTanqueWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CustomTimePicker(
            title: 'Hora de Registro',
            controller: widget.horaController,
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
            controller: widget.volumenController,
            title: 'Volumen',
            onChange: (value) => () {},
          ),
        ),
        DropDown(
            width: MediaQuery.of(context).size.width,
            label: 'Tipo de combustible',
            requiredData: true,
            initialValue: widget.combustibleController.text,
            dropKey: widget.dropKey, // Ahora es único
            key: ValueKey(widget.step),
            items: widget.listaCombustibles.map((combustible) {
              return {'id': combustible.id, 'label': combustible.nombre};
            }).toList(),
            onChange: (String? value) {
              widget.onChange != null
                  ? widget.onChange!(value)
                  : widget.onChange!('');
            }),
      ],
    );
  }
}
