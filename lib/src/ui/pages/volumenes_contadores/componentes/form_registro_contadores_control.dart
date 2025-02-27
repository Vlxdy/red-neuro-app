import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/text_input.dart';
import 'package:control_ventas_movil/src/ui/common/drop_down/drop_down.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/registro_meters_store.dart';
import 'package:control_ventas_movil/src/models/registro_meters.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/componentes/form_registro_contadores_final.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';

class RegistroContadores extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final List<DropDownType> tipoMedicion;
  final List<Dispensador> dispensadores;
  final List<DropDownType> listaCombustibles;

  const RegistroContadores({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.tipoMedicion,
    required this.dispensadores,
    required this.listaCombustibles,
  });

  @override
  State<RegistroContadores> createState() => _RegistroContadoresState();
}

class _RegistroContadoresState extends State<RegistroContadores> {
  DropDownType? selectedTipoMedicion;
  int _currentStep = 0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<DropdownButton2State> dropKeyTipoMedicion =
      GlobalKey<DropdownButton2State>();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      appBar: _buildAppBar(theme),
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
                dropKey: dropKeyTipoMedicion,
                items: widget.tipoMedicion
                    .map((e) => {'id': e.id, 'label': e.nombre})
                    .toList(),
                onChange: (value) {
                  setState(() {
                    selectedTipoMedicion = widget.tipoMedicion
                        .firstWhere((element) => element.id == value);
                  });
                },
                validate: (value, alias) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona un tipo de medición';
                  }
                  return null;
                },
              ),
              Expanded(
                child: Stepper(
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  controlsBuilder:
                      (BuildContext context, ControlsDetails details) {
                    return const SizedBox.shrink(); // Sin botones
                  },
                  steps: widget.dispensadores.map((dispensador) {
                    return Step(
                      title: const Text(''), // Sin titulo
                      content: DispensadorWidget(
                        dispensador: dispensador,
                        listaCombustibles: widget.listaCombustibles,
                      ),
                      isActive: _currentStep >=
                          widget.dispensadores.indexOf(dispensador),
                    );
                  }).toList(),
                  elevation: 0, // Sin elevación
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
                    _currentStep -= 1;
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(_currentStep == 0 ? 'Cancelar' : 'Anterior'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_currentStep < widget.dispensadores.length - 1) {
                  setState(() {
                    _currentStep += 1;
                  });
                } else {
                  // Finalizar registro
                  if (_formKey.currentState?.validate() ?? false) {
                    // Crear la lista de registros y guardarlos en el store
                    RegistroMeterStore registro = RegistroMeterStore(
                      tipoMedicion: selectedTipoMedicion!,
                      dispensadores: widget.dispensadores.map((dispensador) {
                        return DispensadorStore(
                          hora: dispensador.horaRegistro,
                          idDispensador: dispensador.idDispensador,
                          codigo: dispensador.codigo,
                          mangueras: dispensador.mangueras.map((manguera) {
                            return MangueraStore(
                                idManguera: manguera.idManguera,
                                codigo: manguera.codigo,
                                combustible: manguera.selectedCombustible!,
                                meter: 3000
                                //int.parse(manguera.meterController.text),
                                );
                          }).toList(),
                        );
                      }).toList(),
                    );

                    // Guardar el registro en el store
                    context
                        .read<RegistroMetersStore>()
                        .guardarRegistro([registro]);

                    /*     // Volver atrás en el stack de navegación
                    Navigator.pop(context); */
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const FormRegistroContadoresFinal(),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
              ),
              child: Text(
                _currentStep == widget.dispensadores.length - 1
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

  AppBar _buildAppBar(ThemeController theme) {
    final store = context.watch<RegistroMetersStore>();
    return AppBar(
      automaticallyImplyLeading:
          false, // Oculta la flecha de retroceso predeterminada
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: theme.secondary),
              const SizedBox(width: 8),
              Text(widget.titulo,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: theme.secondary)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close), // Ícono "X" para cerrar el modal
            onPressed: () {
              store.limpiarRegistros();
              Navigator.pop(context); // Cierra el modal
            },
          ),
        ],
      ),
    );
  }
}

class Dispensador {
  final String idDispensador;
  final String codigo;
  String horaRegistro;
  final List<Manguera> mangueras;

  Dispensador({
    required this.idDispensador,
    required this.codigo,
    String? horaRegistro,
    required this.mangueras,
  }) : horaRegistro = horaRegistro ?? _getCurrentTime();

  static String _getCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }
}

class Manguera {
  final String idManguera;
  final String codigo;
  DropDownType? selectedCombustible;
  TextEditingController? _meterController;
  String? meterValue;

  Manguera({required this.idManguera, required this.codigo}) {
    _meterController = TextEditingController();
  }
}

class DispensadorWidget extends StatefulWidget {
  final Dispensador dispensador;
  final List<DropDownType> listaCombustibles;

  const DispensadorWidget({
    super.key,
    required this.dispensador,
    required this.listaCombustibles,
  });

  @override
  DispensadorWidgetState createState() => DispensadorWidgetState();
}

class DispensadorWidgetState extends State<DispensadorWidget> {
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && mounted) {
      setState(() {
        widget.dispensador.horaRegistro =
            "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Dispensador: ${widget.dispensador.codigo}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(
                    text: widget.dispensador.horaRegistro,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Hora',
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time, color: theme.secondary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.dispensador.mangueras.map(
          (manguera) => MangueraWidget(
            manguera: manguera,
            listaCombustibles: widget.listaCombustibles,
          ),
        ),
      ],
    );
  }
}

class MangueraWidget extends StatefulWidget {
  final Manguera manguera;
  final List<DropDownType> listaCombustibles;

  const MangueraWidget({
    super.key,
    required this.manguera,
    required this.listaCombustibles,
  });

  @override
  MangueraWidgetState createState() => MangueraWidgetState();
}

class MangueraWidgetState extends State<MangueraWidget> {
  final GlobalKey<DropdownButton2State> dropKeyCombustible =
      GlobalKey<DropdownButton2State>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Manguera: ${widget.manguera.codigo}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropDown(
          width: MediaQuery.of(context).size.width,
          label: 'Tipo de combustible',
          requiredData: true,
          dropKey: dropKeyCombustible,
          items: widget.listaCombustibles
              .map((e) => {'id': e.id, 'label': e.nombre})
              .toList(),
          onChange: (value) {
            setState(() {
              widget.manguera.selectedCombustible = widget.listaCombustibles
                  .firstWhere((element) => element.id == value);
            });
          },
          validate: (value, alias) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona un tipo de combustible';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextInput(
          controller: widget.manguera._meterController,
          title: 'Meter',
          requiredData: true,
          onlyNumbers: true,
          /*  onChange: (String? value) => store. = value ?? ' */
          onChange: (value) {
            setState(() {
              Logger.info(value.toString());
              widget.manguera.meterValue = value;
            });
          },
          /*  validate: (value, alias) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el valor del meter';
            }
            return null;
          }, */
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

void showRegistroContadoresModal(BuildContext context) {
  String horaActual = DateFormat('HH:mm').format(DateTime.now());

  List<DropDownType> listaCombustibles = [
    DropDownType(id: "1", nombre: "Diesel Oil"),
    DropDownType(id: "2", nombre: "Gasolina 95"),
    DropDownType(id: "3", nombre: "Gasolina 98"),
  ];

  List<DropDownType> tiposMediciones = [
    DropDownType(id: "1", nombre: "Jornada inicial"),
    DropDownType(id: "2", nombre: "Jornada final"),
    DropDownType(id: "3", nombre: "A pedido"),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.95,
      child: RegistroContadores(
        titulo: "Registro de contadores",
        descripcion:
            "Registrarás el valor de cada meter de manguera de los dispensadores de la EESS",
        tipoMedicion: tiposMediciones,
        listaCombustibles: listaCombustibles,
        dispensadores: [
          /*         Dispensador(
            idDispensador: "1",
            codigo: "DISP-200",
            horaRegistro: horaActual,
            mangueras: [
              Manguera(idManguera: "1", codigo: "M001"),
              Manguera(idManguera: "1", codigo: "M002"),
            ],
          ), */
          Dispensador(
            idDispensador: "2",
            codigo: "DISP-201",
            horaRegistro: horaActual,
            mangueras: [
              Manguera(idManguera: "1", codigo: "M003"),
            ],
          ),
          /*        Dispensador(
            idDispensador: "3",
            codigo: "DISP-202",
            horaRegistro: horaActual,
            mangueras: [
              Manguera(idManguera: "1", codigo: "M004"),
            ],
          ),
          Dispensador(
            idDispensador: "3",
            codigo: "DISP-203",
            horaRegistro: horaActual,
            mangueras: [
              Manguera(idManguera: "5", codigo: "M005"),
            ],
          ), */
        ],
      ),
    ),
  );
}
