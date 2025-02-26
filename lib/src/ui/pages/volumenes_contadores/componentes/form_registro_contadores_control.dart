import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegistroContadores extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final List<String> tipoMedicion;
  final List<Dispensador> dispensadores;
  final List<String> listaCombustibles;

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
  String? selectedTipoMedicion;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.menu_book, color: theme.secondary),
            const SizedBox(width: 8),
            Text(widget.titulo, style: TextStyle(color: theme.secondary)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.descripcion, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedTipoMedicion,
              onChanged: (value) {
                setState(() {
                  selectedTipoMedicion = value;
                });
              },
              items: widget.tipoMedicion
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Tipo de medición'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.dispensadores.length,
                itemBuilder: (context, index) {
                  return DispensadorWidget(
                    dispensador: widget.dispensadores[index],
                    listaCombustibles: widget.listaCombustibles,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Dispensador {
  final String nombre;
  String horaRegistro;
  final List<Manguera> mangueras;

  Dispensador({
    required this.nombre,
    String? horaRegistro,
    required this.mangueras,
  }) : horaRegistro = horaRegistro ?? _getCurrentTime();

  static String _getCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }
}

class Manguera {
  final String codigo; // Nuevo código de manguera
  String? selectedCombustible;
  final TextEditingController meterController;

  Manguera({required this.codigo}) : meterController = TextEditingController();
}

class DispensadorWidget extends StatefulWidget {
  final Dispensador dispensador;
  final List<String> listaCombustibles;

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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dispensador: ${widget.dispensador.nombre}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Hora de registro:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: Row(
                    children: [
                      Text(widget.dispensador.horaRegistro,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...widget.dispensador.mangueras.map(
              (manguera) => MangueraWidget(
                manguera: manguera,
                listaCombustibles: widget.listaCombustibles,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MangueraWidget extends StatefulWidget {
  final Manguera manguera;
  final List<String> listaCombustibles;

  const MangueraWidget({
    super.key,
    required this.manguera,
    required this.listaCombustibles,
  });

  @override
  MangueraWidgetState createState() => MangueraWidgetState();
}

class MangueraWidgetState extends State<MangueraWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Manguera: ${widget.manguera.codigo}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          value: widget.manguera.selectedCombustible,
          onChanged: (value) {
            setState(() {
              widget.manguera.selectedCombustible = value;
            });
          },
          items: widget.listaCombustibles
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          decoration: const InputDecoration(labelText: 'Tipo de combustible'),
        ),
        TextField(
          controller: widget.manguera.meterController,
          decoration: const InputDecoration(labelText: 'Meter'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

void showRegistroContadoresModal(BuildContext context) {
  String horaActual = DateFormat('HH:mm').format(DateTime.now());

  List<String> listaCombustibles = ["Diesel Oil", "Gasolina 95", "Gasolina 98"];

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
        tipoMedicion: ["Litros", "Galones"],
        listaCombustibles: listaCombustibles,
        dispensadores: [
          Dispensador(
            nombre: "Dispensador 1",
            horaRegistro: horaActual,
            mangueras: [
              Manguera(codigo: "M001"),
              Manguera(codigo: "M002"),
            ],
          ),
          Dispensador(
            nombre: "Dispensador 2",
            horaRegistro: horaActual,
            mangueras: [
              Manguera(codigo: "M003"),
            ],
          ),
        ],
      ),
    ),
  );
}
