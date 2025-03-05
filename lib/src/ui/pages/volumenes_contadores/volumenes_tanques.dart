import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques_service.dart';
import 'package:flutter/material.dart';

class VolumenesTanques extends StatefulWidget {
  const VolumenesTanques({super.key});

  @override
  State<VolumenesTanques> createState() => VolumenesTanquesScreen();
}

class VolumenesTanquesScreen extends State<VolumenesTanques> {
  //service
  late VolumenesTanquesService service;
  late Future<List<VolumenTanque>> futurevolumenes;
  @override
  void initState() {
    super.initState();
    service = VolumenesTanquesService('/mobile', context);
    futurevolumenes = service.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    final List<Map<String, String>> volumenes = [
      {'hora': '08:20', 'tanque': '1', 'combustible': 'DO', 'volumen': '23000'},
      {'hora': '08:10', 'tanque': '2', 'combustible': 'GE', 'volumen': '20000'},
      {'hora': '08:10', 'tanque': '3', 'combustible': 'GE', 'volumen': '20000'},
      {'hora': '00:00', 'tanque': '1', 'combustible': 'DO', 'volumen': '3000'},
      {'hora': '00:00', 'tanque': '2', 'combustible': 'GE', 'volumen': '5000'},
      {'hora': '00:00', 'tanque': '3', 'combustible': 'GE', 'volumen': '10000'},
    ];

    return Scaffold(
      backgroundColor: theme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.local_gas_station, color: theme.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Volúmenes de combustible \n en Tanques',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: SimpleButton(
                    title: "+ Registrar volúmenes",
                    onTap: () {
                      // Acción para registrar volúmenes
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<VolumenTanque>>(
                future: futurevolumenes, // Llamada al servicio
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator()); // Muestra un indicador de carga
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error: ${snapshot.error}')); // Muestra errores si ocurren
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text(
                            'No hay datos disponibles')); // Muestra un mensaje si no hay datos
                  }

                  final volumenes = snapshot.data!; // Datos obtenidos

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        // Encabezados de la tabla
                        TableRow(
                          decoration: BoxDecoration(color: theme.white),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Hora', textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child:
                                  Text('Tanque', textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Comb.', textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child:
                                  Text('Volumen', textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                        // Filas de la tabla con datos obtenidos
                        ...volumenes.asMap().entries.map((entry) {
                          int index = entry.key;
                          VolumenTanque volumen = entry.value;
                          return TableRow(
                            decoration: BoxDecoration(
                              color:
                                  index.isEven ? theme.primary50 : theme.white,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(volumen.hora,
                                    textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(volumen.tanques!.nombre,
                                    textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  backgroundColor: volumen.combustible == 'DO'
                                      ? theme.primary
                                      : theme.secondary,
                                  child: Text(
                                    volumen.combustible!.codigo,
                                    style: TextStyle(color: theme.white),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(volumen.volumen.toString(),
                                    textAlign: TextAlign.center),
                              ),
                            ],
                          );
                        })
                      ],
                    ),
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
