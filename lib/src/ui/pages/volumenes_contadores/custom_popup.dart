import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/meters_mangueras.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques.dart';

class PopupVolumenes extends StatelessWidget {
  final Icon icon;
  final String title;
  final Color color;

  const PopupVolumenes(
      {super.key,
      required this.icon,
      required this.title,
      required this.color});

  void _onMenuItemSelected(BuildContext context, int value) {
    switch (value) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const VolumenesTanques()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MetersManguerasScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: Column(
        children: [
          icon,
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
      onSelected: (int value) {
        _onMenuItemSelected(context, value);
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<int>(
            value: 0,
            child: ListTile(
              leading: Icon(Icons.local_gas_station),
              title: Text('Volúmenes Tanques'),
            ),
          ),
          const PopupMenuItem<int>(
            value: 1,
            child: ListTile(
              leading: Icon(Icons.speed),
              title: Text('Cantidad Mangueras'),
            ),
          ),
          // Agregar más opciones si es necesario
        ];
      },
    );
  }
}
