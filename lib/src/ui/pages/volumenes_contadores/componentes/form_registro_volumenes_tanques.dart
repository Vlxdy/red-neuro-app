import 'dart:io';

import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/enums.dart';
import 'package:control_ventas_movil/src/models/combustible.dart';
import 'package:control_ventas_movil/src/models/estacion_servicio.dart';
import 'package:control_ventas_movil/src/models/registro_meters.dart';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:control_ventas_movil/src/ui/common/drop_down/drop_down.dart';
import 'package:control_ventas_movil/src/ui/common/form_stepper/form_stepper.dart';
import 'package:control_ventas_movil/src/ui/common/selector_image/multiple_campo_fotografia.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/date_input.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/text_input.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/registro_volumenes_store.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques_service.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FormVolumenesTanques extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final List<TanquesEstacion> tanques;
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
  bool? _tieneFotos;

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
    late DateTime fechaHoy = DateTime.now();

    datosFormulario = FormularioRegistroVolumenes(
      datos: List<ItemVolumenTanque>.generate(widget.tanques.length, (index) {
        final [hours, minutes] = horaControllers[index].text.split(':');
        DateTime dateWithTime = DateTime.parse(fechaHoy.toIso8601String());
        dateWithTime = DateTime(
            dateWithTime.year,
            dateWithTime.month,
            dateWithTime.day,
            int.tryParse(hours) ?? 0,
            int.tryParse(minutes) ?? 0);
        return ItemVolumenTanque(
          idTanque: widget.tanques[index].id,
          hora: dateWithTime.toIso8601String(),
          tipoMedicion: _tipoSeleccionado ?? '',
          volumen: int.tryParse(volumenControllers[index].text) ?? 0,
          idCombustible: combustibleControllers[index].text,
          fechaRegistroApp: fechaHoy.toIso8601String(),
        );
      }),
    );
    setState(() {
      _finalizado = true;
    });
  }

  void _guardarFormulario() {
    service.registrarVolumenes(context, datosFormulario);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final store = context.watch<RegistroVolumenesStore>();

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
                        store.setTipoMedicion = value!;
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
                          ] else
                            const SizedBox(height: 10),
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
                                tanque: widget.tanques[_currentStep],
                                onChange: (String? value) {
                                  setState(() {
                                    combustibleControllers[_currentStep].text =
                                        value ?? '';
                                  });
                                },
                                step: _currentStep,
                                tieneFotos: _tieneFotos,
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
                if (_finalizado) {
                  setState(() {
                    _finalizado = false;
                  });
                } else {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep--;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(_finalizado
                  ? 'Anterior'
                  : _currentStep == 0
                      ? 'Cancelar'
                      : 'Anterior'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _tieneFotos =
                    store.tieneFotos(widget.tanques[_currentStep].id));
                if (_currentStep < widget.tanques.length - 1) {
                  if (service.validateForm(_formKey) && _tieneFotos!) {
                    setState(() {
                      _currentStep++;
                      _tieneFotos = null;
                    });
                  }
                } else {
                  if (_finalizado) {
                    _guardarFormulario();
                  } else {
                    if (service.validateForm(_formKey) && _tieneFotos!) {
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
  final TanquesEstacion tanque;
  final List<Combustible> listaCombustibles;
  final TextEditingController horaController;
  final TextEditingController combustibleController;
  final TextEditingController volumenController;
  final GlobalKey<DropdownButton2State> dropKey;
  final Function(String?)? onChange;
  final int step;
  final bool? tieneFotos;

  const VolumenTanqueWidget({
    super.key,
    required this.tanque,
    required this.listaCombustibles,
    required this.horaController,
    required this.combustibleController,
    required this.volumenController,
    required this.dropKey,
    this.onChange,
    required this.step,
    this.tieneFotos,
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
    final itemResumen = store.obtenerDatos(widget.tanque.id) ??
        ItemResumen(nombre: widget.tanque.nombre);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanque: ${widget.tanque.nombre}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
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
            onChange: (value) => {
              store.actualizarDatos(
                itemResumen.copyWith(hora: value),
                widget.tanque.id,
              )
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
            onChange: (value) => {
              store.actualizarDatos(
                itemResumen.copyWith(volumen: int.parse(value)),
                widget.tanque.id,
              )
            },
          ),
        ),
        DropDown(
          width: MediaQuery.of(context).size.width,
          label: 'Tipo de combustible',
          requiredData: true,
          initialValue: widget.combustibleController.text,
          dropKey: widget.dropKey,
          key: ValueKey(widget.step),
          items: widget.listaCombustibles.map((combustible) {
            return {'id': combustible.id, 'label': combustible.nombre};
          }).toList(),
          onChange: (String? value) {
            widget.onChange != null
                ? widget.onChange!(value)
                : widget.onChange!('');
            store.actualizarDatos(
              itemResumen.copyWith(
                  combustible: widget.listaCombustibles
                      .firstWhere((combustible) => combustible.id == value)
                      .nombre),
              widget.tanque.id,
            );
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
        if (widget.tieneFotos != null && widget.tieneFotos == false)
          Text(
            'Debe subir por lo menos una foto',
            style: TextStyle(color: theme.error),
          ),
        MultipleCampoFotografia(
          titulo: 'Respaldo',
          paths: store.obtenerFotos(widget.tanque.id),
          onClick: (path) => store.actualizarFoto(path, widget.tanque.id),
          onDelete: (index) => store.eliminarFoto(index, widget.tanque.id),
          key: Key('foto$step'),
          max: 2,
        )
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
    final store = context.watch<RegistroVolumenesStore>();
    final tipoMedicion = store.tipoMedicion;
    final keys = store.datos.keys;
    final theme = ThemeController.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.descripcion, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              text: 'Tipo de Medición: ',
              style: TextStyle(color: theme.secondary),
              children: <TextSpan>[
                TextSpan(
                  text: tipoMedicion,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (keys.isEmpty) const Text("No hay datos disponibles"),
          ...keys.map((key) {
            final fotos = store.obtenerFotos(key);
            final dato = store.obtenerDatos(key);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanque ${dato?.nombre}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.secondary,
                    fontSize: 15,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: 'Hora: ',
                    style: TextStyle(color: theme.secondary),
                    children: <TextSpan>[
                      TextSpan(
                        text: dato?.hora,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: 'Combustible: ',
                    style: TextStyle(color: theme.secondary),
                    children: <TextSpan>[
                      TextSpan(
                        text: dato?.combustible,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: 'Volumen: ',
                    style: TextStyle(color: theme.secondary),
                    children: <TextSpan>[
                      TextSpan(
                        text: dato!.volumen.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (fotos.isNotEmpty) const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: fotos.map((foto) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.file(
                        File(foto),
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      ),
                    );
                  }).toList(),
                ),
                const Divider(),
              ],
            );
          }),
        ],
      ),
    );
  }
}
