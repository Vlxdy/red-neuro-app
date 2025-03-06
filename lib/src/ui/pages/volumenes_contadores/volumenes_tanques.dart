import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:control_ventas_movil/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/componentes/form_registro_volumenes_tanques.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

 void _mostrarModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Permite que el modal se expanda
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.9, // Ajusta el tamaño del modal (90% de la pantalla)
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Ajusta si hay teclado
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Registrar Volúmenes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FormVolumenesTanques(), // Asegúrate de que el formulario no tenga restricciones de tamaño
              ),
            ],
          ),
        ),
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

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
                  child: ElevatedButton(
                    onPressed: () {
                      _mostrarModal(context);
                      // Primero, accede a los registros almacenados en el store
                      // store.limpiarRegistros();
                      // showRegistroContadoresModal(context);
                    },
                    child: const Text('+ Registrar volúmenes'),
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
                  return Expanded(
                      child: CustomDesktopDataTable(
                    columnas: [
                      CriterioOrdenType(nombre: 'Hora'),
                      CriterioOrdenType(nombre: 'Tanque'),
                      CriterioOrdenType(nombre: 'Combustible'),
                      CriterioOrdenType(nombre: 'Volumen'),
                    ],
                    contenidoTabla: 
                    volumenes.isEmpty ?
                    [] :
                    (volumenes).map((volumen) {
                      String hexColor = volumen.combustible!.color;
                      Color color =
                        Color(int.parse('0xFF${hexColor.substring(1)}'));

                      return [
                      Center(
                        child: Text(
                        DateFormat('HH:mm')
                          .format(DateTime.parse(volumen.hora)),
                        textAlign: TextAlign.center,
                        ),
                      ),
                      Center(child: Text(volumen.tanques!.nombre)),
                      Center(
                        child: Container(
                        decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 12.0),
                        child: Text(
                        volumen.combustible!.codigo,
                        style: TextStyle(color: theme.white),
                        overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      Center(child: Text(volumen.volumen)),
                      ];
                    }).toList(),

                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
