import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/combustible_card.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/tanque_registrar_venta.dart';
import 'package:flutter/material.dart';

class TanqueAdicionalScreen extends StatelessWidget {
  const TanqueAdicionalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final int ventasDiesel = 12;
    final int ventasGasolina = 22;

    return Scaffold(
      backgroundColor: theme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_gas_station, color: theme.primary, size: 28),
                SizedBox(width: 8),
                Text(
                  'Tanque adicional',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
            Text(
              'Venta de combustible a vehículos con DOBLE TANQUE',
              style: TextStyle(fontSize: 14, color: theme.primary),
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
                  color: theme.primary,
                  onPressedNuevaVenta: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NuevaVentaScreen()),
                    );
                  },
                ),
                CombustibleCard(
                  title: 'GASOLINA ULTRA PREMIUM 100',
                  ventasRegistradas: ventasGasolina,
                  color: theme.secondary,
                  onPressedNuevaVenta: () {
                    Navigator.push(
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
