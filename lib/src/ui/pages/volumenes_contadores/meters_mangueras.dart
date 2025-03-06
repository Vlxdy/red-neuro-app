import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/meters_service.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/componentes/form_registro_contadores_control.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/registro_meters_store.dart';

class MetersManguerasScreen extends StatefulWidget {
  const MetersManguerasScreen({super.key});

  @override
  State<MetersManguerasScreen> createState() => _MetersManguerasScreen();
}

class _MetersManguerasScreen extends State<MetersManguerasScreen> {
  late MeterService service;
  late Future<List<Map<String, dynamic>>> futureMeters;

  @override
  void initState() {
    super.initState();
    service = MeterService('/mobile', context);
    futureMeters = service.getMetersListado();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final store = context.watch<RegistroMetersStore>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: theme.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Meters de Mangueras',
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
                      // Primero, accede a los registros almacenados en el store
                      store.limpiarRegistros();
                      showRegistroContadoresModal(context);
                    },
                    child: const Text('+ Registrar contadores'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: futureMeters,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar datos'));
                  }
                  final data = snapshot.data ?? [];

                  if (data.isEmpty) {
                    return const Center(
                        child: Text('No hay datos disponibles'));
                  }

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final volumen = data[index];
                      final hora = DateFormat('HH:mm')
                          .format(DateTime.parse(volumen['hora']));

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hora: $hora',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              // Mapeo de los dispensadores
                              ...(volumen['dispensadores'] as List)
                                  .map((dispensador) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Dispensador
                                    Text(
                                      'Dispensador: ${dispensador['codigo']}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    // Mapeo de las mangueras del dispensador
                                    Table(
                                      // Eliminar borde de la tabla
                                      children: [
                                        // Fila para los encabezados de los campos
                                        TableRow(
                                          /* decoration: BoxDecoration(
                                              color: Colors.blueAccent), */
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8.0),
                                              child: Center(
                                                child: Text(
                                                  'Manguera',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme.black),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8.0),
                                              child: Center(
                                                child: Text(
                                                  'Combustible',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme.black),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8.0),
                                              child: Center(
                                                child: Text(
                                                  'Contador',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme.black),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Mapeo de las mangueras
                                        ...(dispensador['mangueras'] as List)
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final indexM = entry.key;
                                          final manguera = entry.value;
                                          // Obtener el color hexadecimal del combustible
                                          String hexColor =
                                              manguera['combustible']
                                                  ['combustiblecolor'];
                                          Color color = Color(int.parse(
                                              '0xFF${hexColor.substring(1)}'));

                                          return TableRow(
                                            decoration: BoxDecoration(
                                              color: indexM.isEven
                                                  ? theme.primary50
                                                  : theme.white,
                                            ),
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Center(
                                                    //child: Text('${indexM + 1}'),
                                                    child: Text(
                                                        manguera['codigo'])),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Center(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          color, // Color dinámico
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    //width: 90, // Ancho fijo
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 6.0,
                                                        horizontal: 12.0),
                                                    child: Align(
                                                      alignment: Alignment
                                                          .center, // Alineación central
                                                      child: Text(
                                                        manguera['combustible'][
                                                            'combustiblecodigo'],
                                                        style: TextStyle(
                                                            color: theme.white),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Center(
                                                  child: Text(
                                                      '${manguera['meter']}'),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
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
