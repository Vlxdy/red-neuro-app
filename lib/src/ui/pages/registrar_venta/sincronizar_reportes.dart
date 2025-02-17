import 'package:flutter/material.dart';

class SincronizarReportesScreen extends StatelessWidget {
  const SincronizarReportesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final noSincronizados = [
      {'fecha': '10/12/2024', 'eess': 'EESS Avaroa'},
      {'fecha': '11/12/2024', 'eess': 'EESS Avaroa'},
      {'fecha': '09/12/2024', 'eess': 'EESS Avaroa'},
    ];
    final sincronizados = [
      {'fecha': '08/12/2024', 'eess': 'EESS Santa Rosa'},
      {'fecha': '07/12/2024', 'eess': 'EESS Santa Rosa'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizar Reportes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No sincronizados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            ...noSincronizados.map(
                  (item) => _ReporteItem(
                fecha: item['fecha']!,
                eess: item['eess']!,
                iconData: Icons.sync,
                iconColor: Colors.orange,
                onTap: () {

                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sincronizados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            ...sincronizados.map(
                  (item) => _ReporteItem(
                fecha: item['fecha']!,
                eess: item['eess']!,
                iconData: Icons.check_circle,
                iconColor: Colors.green,
                onTap: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReporteItem extends StatelessWidget {
  final String fecha;
  final String eess;
  final IconData iconData;
  final Color iconColor;
  final VoidCallback? onTap;

  const _ReporteItem({
    Key? key,
    required this.fecha,
    required this.eess,
    required this.iconData,
    required this.iconColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(iconData, color: iconColor, size: 32),
      title: Text(fecha),
      subtitle: Text(eess),
      trailing: onTap != null
          ? IconButton(
        icon: Icon(iconData, color: iconColor),
        onPressed: onTap,
      )
          : null,
    );
  }
}
