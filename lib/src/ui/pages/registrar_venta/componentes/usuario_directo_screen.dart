import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/usuario_directo_paso2_screen.dart';
import 'package:flutter/material.dart';

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

  void _tomarFoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de tomar foto no implementada')),
    );
  }

  void _siguientePaso() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const UsuarioDirectoPaso2Screen()),
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
    final theme = ThemeController.instance;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_gas_station, color: theme.bgBlue, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Venta de combustible a\nUsuarios Directos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.bgBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Registrarás una nueva venta de combustible',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Paso 1 de 2',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nro. de CI del comprador',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal),
              ),
              TextField(
                controller: ciController,
                decoration: InputDecoration(
                  hintText: 'Ingrese el CI del comprador',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nro. de Placa de vehículo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              TextField(
                controller: placaController,
                decoration: InputDecoration(
                  hintText: 'Ej. 546PYP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fotografías',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _tomarFoto,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.photo_camera, color: Colors.teal),
                label: const Text('Tomar foto'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toma fotografías de la placa del vehículo y de la cédula de identidad del comprador',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _siguientePaso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.bgBlue,
                  foregroundColor: Colors.white,
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
                  foregroundColor: theme.bgBlue,
                  side: BorderSide(color: theme.bgBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: Icon(Icons.cancel, color: theme.bgBlue),
                label: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
