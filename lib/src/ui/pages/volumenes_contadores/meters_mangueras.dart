import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/navbar_volumenes.dart';
import 'package:flutter/material.dart';

class MetersManguerasScreen extends StatelessWidget {
  const MetersManguerasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    final List<Map<String, Object>> volumenes = [
      {
        'hora': '08:20',
        'dispensador': '01',
        'mangueras': [
          {'id': 1, 'combustible': 'DO', 'contador': '15003'},
          {'id': 2, 'combustible': 'GE', 'contador': '20450'},
          {'id': 3, 'combustible': 'GE', 'contador': '11450'},
        ]
      },
      {
        'hora': '08:25',
        'dispensador': '02',
        'mangueras': [
          {'id': 1, 'combustible': 'DO', 'contador': '20000'},
        ]
      },
      {
        'hora': '08:20',
        'dispensador': '01',
        'mangueras': [
          {'id': 1, 'combustible': 'DO', 'contador': '15003'},
          {'id': 2, 'combustible': 'GE', 'contador': '20450'},
          {'id': 3, 'combustible': 'GE', 'contador': '11450'},
        ]
      },
      {
        'hora': '08:20',
        'dispensador': '01',
        'mangueras': [
          {'id': 1, 'combustible': 'DO', 'contador': '15003'},
          {'id': 2, 'combustible': 'GE', 'contador': '20450'},
          {'id': 3, 'combustible': 'GE', 'contador': '11450'},
        ]
      },
      {
        'hora': '08:20',
        'dispensador': '01',
        'mangueras': [
          {'id': 1, 'combustible': 'DO', 'contador': '15003'},
          {'id': 2, 'combustible': 'GE', 'contador': '20450'},
          {'id': 3, 'combustible': 'GE', 'contador': '11450'},
        ]
      },
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EESS Santa Rosa',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '12/12/2024 00:00 - 08:00',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: theme.bgBlue, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Meters de Manguera',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.bgBlue,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('+ Registrar contadores'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: volumenes.length,
                itemBuilder: (context, index) {
                  final volumen = volumenes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hora: ${volumen['hora']}  -  Dispensador: ${volumen['dispensador']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Manguera',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('Combustible',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('Contador',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(),
                              ...(volumen['mangueras'] as List)
                                  .map((manguera) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                    '${(volumen['mangueras'] as List).indexOf(manguera) + 1}'),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                  child: Text(
                                                    manguera['combustible'],
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                    '${manguera['contador']}'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavBarVolumenes(selectedIndex: 1),
    );
  }
}
