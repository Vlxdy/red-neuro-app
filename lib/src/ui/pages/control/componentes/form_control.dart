import 'package:control_ventas_movil/src/ui/common/drop_down/drop_down.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class FormControl extends StatefulWidget {
  const FormControl({super.key});

  @override
  State<FormControl> createState() => _FormControl();
}

class _FormControl extends State<FormControl> {

  final GlobalKey<DropdownButton2State> dropKey = GlobalKey<DropdownButton2State>();
  final GlobalKey<DropdownButton2State> dropKeyHorario = GlobalKey<DropdownButton2State>();

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecciona una estación de servicio'),
        const SizedBox(height: 4),
        DropDown(
          width: MediaQuery.of(context).size.width,
          label: 'EESS Asignadas al regimiento',
          dropKey: dropKey,
          // TODO: Obtener datos del servicio
          items: ['REG-001', 'REG-002'],
          // items: store.estaciones.map((String estacion) {
          //   return DropdownMenuItem<String>(
          //     value: estacion,
          //     child: Text(estacion),
          //   );
          // }).toList(),
          onChange: (value) {
            // store.estacionSeleccionada = value;
          },
        ),
        const SizedBox(height: 16),
        Text('Selecciona un horario'),
        const SizedBox(height: 4),
        DropDown(
          width: MediaQuery.of(context).size.width,
          label: 'Horarios',
          dropKey: dropKeyHorario,
          items: const ['13:30', '14:30', '15:30'],
        )
      ],
    );
  }
}
