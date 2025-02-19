import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/nueva_venta.dart';
import 'package:flutter/material.dart';

class TanqueAdicionalScreen extends StatelessWidget {
  const TanqueAdicionalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final int ventasDiesel = 12;
    final int ventasGasolina = 22;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tanque adicional',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Venta de Diesel a vehículos con DOBLE TANQUE',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FuelCard(
                    title: 'Diesel',
                    ventasRegistradas: ventasDiesel,
                    color: theme.bgBlue,
                    onPressedNuevaVenta: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NuevaVentaScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FuelCard(
                    title: 'Gasolina especial',
                    ventasRegistradas: ventasGasolina,
                    color: Colors.teal,
                    onPressedNuevaVenta: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NuevaVentaScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelCard extends StatelessWidget {
  final String title;
  final int ventasRegistradas;
  final Color color;
  final VoidCallback onPressedNuevaVenta;

  const _FuelCard({
    Key? key,
    required this.title,
    required this.ventasRegistradas,
    required this.color,
    required this.onPressedNuevaVenta,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, color: color),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ventas registradas',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              ventasRegistradas.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onPressedNuevaVenta,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: Text('Nuevaa venta ${title.toUpperCase()}'),
            ),
          ],
        ),
      ),
    );
  }
}
