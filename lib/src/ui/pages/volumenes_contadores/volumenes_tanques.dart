import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/navbar_volumenes.dart';
import 'package:flutter/material.dart';

class VolumenesTanquesScreen extends StatelessWidget {
  const VolumenesTanquesScreen({super.key});

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
        backgroundColor: theme.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.local_gas_station, color: theme.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Volúmenes de conbustible \n en Tanques',
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
                  onTap: () {},
                )),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: theme.white),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Hora', textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Tanque', textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Comb.', textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Volumen', textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                    ...volumenes.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, String> volumen = entry.value;
                      return TableRow(
                        decoration: BoxDecoration(
                          color: index.isEven ? theme.primary50 : theme.white,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(volumen['hora']!,
                                textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(volumen['tanque']!,
                                textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: volumen['combustible'] == 'DO'
                                  ? theme.primary
                                  : theme.secondary,
                              child: Text(
                                volumen['combustible']!,
                                style: TextStyle(color: theme.white),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(volumen['volumen']!,
                                textAlign: TextAlign.center),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavBarVolumenes(selectedIndex: 0),
    );
  }
}
