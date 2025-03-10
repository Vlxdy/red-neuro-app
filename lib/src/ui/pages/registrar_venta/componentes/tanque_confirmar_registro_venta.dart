import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/navbar_registrar_venta.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/services/venta_tanque_service.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/stores/registrar_venta_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConfirmarRegistroScreen extends StatefulWidget {
  final String placa;
  final int numeroFotos;

  const ConfirmarRegistroScreen({
    Key? key,
    required this.placa,
    required this.numeroFotos,
  }) : super(key: key);

  @override
  _ConfirmarRegistroScreenState createState() => _ConfirmarRegistroScreenState();
}

class _ConfirmarRegistroScreenState extends State<ConfirmarRegistroScreen> {
  late VentaTanquesService _service;

  @override
  void initState() {
    _service = VentaTanquesService('', context);
    super.initState();
  }

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
              'Nro. de Placa de vehículo: ${widget.placa}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Fotografías: ${widget.numeroFotos}',
              style: const TextStyle(fontSize: 14),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final store = context.read<RegistrarVentaStore>();

                    await _service.registrarVentaTanqueConMultipart(
                      pathsDeFotos: store.fotos,
                      placa: widget.placa,
                      idCombustible: 2,
                      fechaRegistroApp: DateTime(2024, 03, 01, 8, 0, 1),
                      context: context,
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RegistrarVentaPage()),
                    );
                  },
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
