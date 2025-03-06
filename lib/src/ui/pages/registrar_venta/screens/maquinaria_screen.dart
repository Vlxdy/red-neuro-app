import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:flutter/material.dart';

class MaquinariaScreen extends StatelessWidget {
  const MaquinariaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background,
      body: const Center(
        child: Text(
          'Pantalla de DS2243 Maquinaria',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
