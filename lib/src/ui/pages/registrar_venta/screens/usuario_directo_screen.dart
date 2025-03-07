import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/common/selector_image/multiple_campo_fotografia.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/text_input.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/usuario_directo_registrar_autorizacion.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/stores/registrar_venta_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> inicioMessenger =
    GlobalKey<ScaffoldMessengerState>();

class UsuarioDirectoPage extends StatefulWidget {
  const UsuarioDirectoPage({super.key});

  @override
  State<UsuarioDirectoPage> createState() => _UsuarioDirectoPageState();
}

class _UsuarioDirectoPageState extends State<UsuarioDirectoPage>
    with WidgetsBindingObserver {
  // late InicioService service;
  final TextEditingController ciController = TextEditingController();
  final TextEditingController placaController = TextEditingController();

  void _siguientePaso() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsuarioDirectoScreen2()),
    );
  }

  @override
  void initState() {
    super.initState();
    // service = InicioService('', context);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RegistrarVentaStore>();
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    top: 0, left: 20, right: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_gas_station,
                            color: theme.secondary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Venta de combustible a\nUsuarios Directos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Registrarás una nueva venta de combustible',
                      style: TextStyle(fontSize: 14, color: theme.secondary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Paso 1 de 2',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.secondary),
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      controller: ciController,
                      title: "Ingrese el CI del comprador",
                      placeholder: 'Ej. 10935578',
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      controller: ciController,
                      title: "Nro. de Placa de vehículo",
                      placeholder: 'Ej. 546PYP',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fotografías',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    MultipleCampoFotografia(
                      titulo: 'Fotografías',
                      paths: store.fotos,
                      onClick: (path) => store.fotos = path,
                      onDelete: (index) => store.eliminarFoto(index),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toma fotografías de la placa del vehículo y de la cédula de identidad del comprador',
                      style: TextStyle(fontSize: 12, color: theme.grey),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _siguientePaso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.secondary,
                      foregroundColor: theme.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Siguiente'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.secondary,
                      side: BorderSide(color: theme.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: Icon(Icons.cancel, color: theme.secondary),
                    label: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
