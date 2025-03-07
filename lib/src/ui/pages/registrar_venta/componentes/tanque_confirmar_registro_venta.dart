import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/screens/venta_tanques_screen.dart';
import 'package:flutter/material.dart';

class ConfirmarRegistroScreen extends StatelessWidget {
  final String placa;
  final int numeroFotos;

  const ConfirmarRegistroScreen({
    Key? key,
    required this.placa,
    required this.numeroFotos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final colorPrincipal = theme.secondary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorPrincipal,
        title: const Text(
          'Confirmar registro de la venta',
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '¿Deseas finalizar el registro de la venta?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Las capturas de datos que tomaste serán registradas.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Nro. de Placa de vehículo: $placa',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Fotografías: $numeroFotos',
              style: const TextStyle(fontSize: 14),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => VentaTanquesScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrincipal,
                    foregroundColor: theme.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorPrincipal,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Continuar con el registro'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
