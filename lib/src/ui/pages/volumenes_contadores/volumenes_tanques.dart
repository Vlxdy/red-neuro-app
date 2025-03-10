import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/enums.dart';
import 'package:control_ventas_movil/src/models/combustible.dart';
import 'package:control_ventas_movil/src/models/registro_meters.dart';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/combustibles_store.dart';
import 'package:control_ventas_movil/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/componentes/form_registro_volumenes_tanques.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> volumenTanquesMessenger =
    GlobalKey<ScaffoldMessengerState>();
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

  void _mostrarModal(List<VolumenTanque> volumenes) {
    List<Combustible> listaCombustibles =
        CombustiblesStore.instance.combustibles;

    List<TipoMedicion> tiposMedicion = TipoMedicion.values;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.95,
        child: FormVolumenesTanques(
            titulo: "Registro de contadores",
            descripcion:
                "Registrarás el volumen de combustible em los tanques de la EESS",
            tiposMedicion: tiposMedicion,
            listaCombustibles: listaCombustibles,
            tanques: volumenes.isNotEmpty
                ? volumenes
                : [
                    VolumenTanque(
                        id: "1",
                        hora: "00:02",
                        tipoMedicion: "x",
                        volumen: "300",
                        tanques: TanqueVolumenTanque(
                          nombre: "Tanque 1",
                          id: "1",
                        )),
                  VolumenTanque(
                        id: "1",
                        hora: "00:02",
                        tipoMedicion: "x",
                        volumen: "300",
                        tanques: TanqueVolumenTanque(
                          nombre: "Tanque 2",
                          id: "3",
                        )),
                    VolumenTanque(
                        id: "1",
                        hora: "00:02",
                        tipoMedicion: "x",
                        volumen: "300"),
                    VolumenTanque(
                        id: "1",
                        hora: "00:02",
                        tipoMedicion: "x",
                        volumen: "300"),
                  ]),
      ),
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
                    // onPressed: () {
                    //   _mostrarModal(context);
                    //   // Primero, accede a los registros almacenados en el store
                    //   // store.limpiarRegistros();
                    //   // showRegistroContadoresModal(context);
                    // },
                    onPressed: () async {
                      final volumenes =
                          await futurevolumenes; // Espera a que se carguen los datos
                      _mostrarModal(
                          volumenes); // Ahora mandamos los datos ya cargados
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
                    contenidoTabla: volumenes.isEmpty
                        ? []
                        : (volumenes).map((volumen) {
                            String hexColor = volumen.combustible!.color;
                            Color color = Color(
                                int.parse('0xFF${hexColor.substring(1)}'));

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
