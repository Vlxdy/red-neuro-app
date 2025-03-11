import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/enums.dart';
import 'package:control_ventas_movil/src/models/combustible.dart';
import 'package:control_ventas_movil/src/models/registro_meters.dart';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:control_ventas_movil/src/ui/common/drop_down/drop_down.dart';
import 'package:control_ventas_movil/src/ui/common/form_stepper/form_stepper.dart';
import 'package:control_ventas_movil/src/ui/common/selector_image/multiple_campo_fotografia.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/date_input.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/text_input.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_store.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/registro_volumenes_store.dart';
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
  late FormularioRegistroVolumenes datosFormulario;

  List<TextEditingController> horaControllers = [];
  List<TextEditingController> combustibleControllers = [];
  List<TextEditingController> volumenControllers = [];
  List<GlobalKey<DropdownButton2State>> dropKeys = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<DropdownButton2State> dropKeyTipoMedicion =
      GlobalKey<DropdownButton2State>();
  DropDownType? selectedTipoMedicion;
  int _currentStep = 0;
  bool _finalizado = false;

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

  void _finalizarDatosFormulario() {
    datosFormulario = FormularioRegistroVolumenes(
      datos: List<ItemVolumenTanque>.generate(widget.tanques.length, (index) {
        return ItemVolumenTanque(
          idTanque: widget.tanques[index].id,
          nombre: widget.tanques[index].tanques?.nombre ?? '',
          hora: horaControllers[index].text,
          tipoMedicion: _tipoSeleccionado ?? '',
          volumen: int.tryParse(volumenControllers[index].text) ?? 0,
          idCombustible: combustibleControllers[index].text,
          fechaRegistroApp: DateTime.now(),
        );
      }),
    );
    setState(() {
      _finalizado = true;
    });
    // print(datosFormulario); // Aquí podrías enviar los datos al backend
  }

  void _guardarFormulario() {
    service.registrarVolumenes(context, datosFormulario);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Medición")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: _finalizado
              ? ResumenWidget(
                  formulario: datosFormulario,
                  descripcion: widget.descripcion,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.descripcion,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    DropDown(
                      width: MediaQuery.of(context).size.width,
                      label: 'Tipo de medición',
                      requiredData: true,
                      dropKey: dropKey,
                      initialValue: _tipoSeleccionado,
                      items: widget.tiposMedicion.map((tipo) {
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
                                volumenController:
                                    volumenControllers[_currentStep],
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
                    // Stepper(
                    //   type: StepperType.horizontal,
                    //   currentStep: _currentStep,
                    //   elevation: 0, // Sin elevación
                    //   controlsBuilder:
                    //       (BuildContext context, ControlsDetails details) {
                    //     return const SizedBox.shrink();
                    //   },

                    //   steps: [
                    //     ...widget.tanques.asMap().entries.map(
                    //       (entry) {
                    //         int index = entry.key;

                    //         return Step(
                    //           title: const Text(""),
                    //           content: Column(
                    //             children: [
                    //               Padding(
                    //                 padding: const EdgeInsets.only(bottom: 8.0),
                    //                 child: CustomTimePicker(
                    //                   title: 'Hora de Registro',
                    //                   controller: horaControllers[index],
                    //                   placeholder: 'Seleccionar hora',
                    //                   requiredData: true,
                    //                   onTap: () {
                    //                     print("Date field tapped");
                    //                   },
                    //                   validate: (value, alias) {
                    //                     if (value == null || value.isEmpty) {
                    //                       return '$alias es obligatorio';
                    //                     }
                    //                     return '';
                    //                   },
                    //                 ),
                    //               ),
                    //               Padding(
                    //                 padding: const EdgeInsets.only(bottom: 8.0),
                    //                 child: CustomTextInput(
                    //                   requiredData: true,
                    //                   controller: volumenControllers[index],
                    //                   title: 'Volumen',
                    //                   onChange: (value) => () {},
                    //                   // validate: (value, alias) =>
                    //                   //     service.validateData(
                    //                   //   context,
                    //                   //   value,
                    //                   //   alias,
                    //                   // ),
                    //                 ),
                    //               ),
                    //               DropDown(
                    //                 width: MediaQuery.of(context).size.width,
                    //                 label: 'Tipo de combustible',
                    //                 requiredData: true,
                    //                 // initialValue:
                    //                 //     combustibleControllers[index].text,
                    //                 dropKey: dropKeys[index], // Ahora es único
                    //                 items: widget.listaCombustibles
                    //                     .map((combustible) {
                    //                   return {
                    //                     'id': combustible.id,
                    //                     'label': combustible.nombre
                    //                   };
                    //                 }).toList(),
                    //                 onChange: (value) {
                    //                   setState(() {
                    //                     combustibleControllers[index].text =
                    //                         value ?? '';
                    //                   });
                    //                 },
                    //               ),
                    //             ],
                    //           ),
                    //           isActive: _currentStep >= index,
                    //         );
                    //       },
                    //     ),
                    //     Step(
                    //       title: const Text(""),
                    //       content: ElevatedButton(
                    //         onPressed: _guardarFormulario,
                    //         child: const Text("Resumen"),
                    //       ),
                    //       isActive: _currentStep == widget.tanques.length,
                    //     ),
                    //   ],
                    // ),
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
                  if (_finalizado) {
                    setState(() {
                      _finalizado = false;
                    });
                  } else {
                    setState(() {
                      _currentStep--;
                    });
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(_currentStep == 0 ? 'Cancelar' : 'Anterior'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_currentStep < widget.tanques.length - 1) {
                  if (service.validateForm(_formKey)) {
                    setState(() => _currentStep++);
                  }
                } else {
                  if (_finalizado) {
                    _guardarFormulario();
                  } else {
                    if (service.validateForm(_formKey)) {
                      _finalizarDatosFormulario();
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
              ),
              child: Text(
                _currentStep == widget.tanques.length - 1
                    ? _finalizado
                        ? 'Enviar'
                        : 'Finalizar registro'
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
    final step = widget.step;
    final store = context.watch<RegistroVolumenesStore>();

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
            key: ValueKey('hora${widget.step}'),
            validate: (value, alias) {
              if (value == null || value.isEmpty) {
                return '$alias es obligatorio';
              }
              return null;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CustomTextInput(
            requiredData: true,
            controller: widget.volumenController,
            title: 'Volumen',
            onlyNumbers: true,
            key: ValueKey('volumen${widget.step}'),
            validate: (value, alias) {
              if (value == null ||
                  int.tryParse(value) == null ||
                  int.tryParse(value)! < 0 ||
                  value.isEmpty) {
                return '$alias debe ser un numero mayor a 0';
              }
              return null;
            },
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
          },
          validate: (value, alias) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona un tipo de combustible';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Fotografías',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        MultipleCampoFotografia(
          titulo: 'Respaldo',
          paths: store.fotos,
          onClick: (path) => store.fotos = path,
          onDelete: (index) => store.eliminarFoto(index),
          key: Key('foto$step'),
          max: 2,
        ),
      ],
    );
  }
}

class ResumenWidget extends StatefulWidget {
  final FormularioRegistroVolumenes formulario;
  final String descripcion;
  final Function(String?)? onChange;

  const ResumenWidget({
    super.key,
    required this.formulario,
    this.onChange,
    required this.descripcion,
  });

  @override
  ResumenWidgetState createState() => ResumenWidgetState();
}

class ResumenWidgetState extends State<ResumenWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.descripcion, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        ...widget.formulario.datos.map((dato) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tanque: ${dato.hora}'),
              Text('Nombre: ${dato.nombre}'),
              Text('Combustible: ${dato.idCombustible}'),
              Text('Volumen: ${dato.volumen}'),
              const SizedBox(height: 10),
            ],
          );
        }),
      ],
    );
  }
}
