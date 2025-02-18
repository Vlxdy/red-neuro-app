import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';

class VentaCard extends StatelessWidget {
  final ThemeController theme;
  final IconData iconData;
  final String titulo;
  final Map<String, String> combustibles;
  final String total;

  const VentaCard({
    super.key,
    required this.theme,
    required this.iconData,
    required this.titulo,
    required this.combustibles,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> combustiblesList = combustibles.entries.toList();
    final int maxVisible = 3;

    return Card(
      elevation: 3,
      color: theme.accent200.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.primary200,
                  child: Icon(iconData, color: theme.white),
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
              ],
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (int i = 0; i < combustiblesList.length && i < maxVisible; i++)
                  _buildChip(
                    label: '${combustiblesList[i].key}: ${combustiblesList[i].value}',
                    color: _getColorForFuel(combustiblesList[i].key),
                  ),
                if (combustiblesList.length > maxVisible)
                  GestureDetector(
                    onTap: () => _showFuelDetails(context),
                    child: Chip(
                      label: Text(
                        '+${combustiblesList.length - maxVisible} más',
                        style: TextStyle(color: theme.background, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: theme.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'Total: $total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({required String label, required Color color}) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: theme.background, fontWeight: FontWeight.w500),
      ),
      backgroundColor: color.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Color _getColorForFuel(String fuelType) {
    final Map<String, Color> fuelColors = {
      'Gasolina': Colors.redAccent,
      'Diesel': Colors.blueAccent,
      'Super': Colors.orangeAccent,
      'Premium': Colors.purpleAccent,
      'Extra': Colors.greenAccent,
      'Diesel6': Colors.tealAccent,
    };

    return fuelColors[fuelType] ?? Colors.grey;
  }

  void _showFuelDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: RoundedRectangleBorder(
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
                  color: theme.primary200,
                ),
              ),
              const SizedBox(height: 12),
              ...combustibles.entries.map(
                    (entry) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForFuel(entry.key).withOpacity(0.3),
                    child: Icon(Icons.local_gas_station, color: _getColorForFuel(entry.key)),
                  ),
                  title: Text(
                    entry.key,
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.primary200),
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
