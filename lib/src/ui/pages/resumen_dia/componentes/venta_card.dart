import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';

class VentaCard extends StatelessWidget {
  final ThemeController theme;
  final IconData iconData;
  final String titulo;
  final String total;
  final Map<String, String> combustibles;

  const VentaCard({
    super.key,
    required this.theme,
    required this.iconData,
    required this.titulo,
    required this.total,
    required this.combustibles,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: theme.accent50,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: theme.primary,
              radius: 20,
              child: Icon(iconData, color: theme.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.black,
                ),
              ),
            ),
            SimpleButton(
              onTap: () => _showFuelDetails(context),
              title: "Ver Detalle",
              background: theme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              total,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Detalles de Combustibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 12),
              ...combustibles.entries.map(
                    (entry) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.primary.withOpacity(0.3),
                    child: Icon(Icons.local_gas_station, color: theme.primary),
                  ),
                  title: Text(
                    entry.key,
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.primary),
                  ),
                  trailing: Text(
                    entry.value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.success),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
