import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/combustible_card.dart';
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
            Row(
              children: const [
                Icon(Icons.local_gas_station, color: Colors.teal, size: 28),
                SizedBox(width: 8),
                Text(
                  'Tanque adicional',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const Text(
              'Venta de combustible a vehículos con DOBLE TANQUE',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisExtent: 200,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              children: [
                CombustibleCard(
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
                CombustibleCard(
                  title: 'GASOLINA ULTRA PREMIUM 100',
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
              ],
            )
          ],
        ),
      ),
    );
  }
}
