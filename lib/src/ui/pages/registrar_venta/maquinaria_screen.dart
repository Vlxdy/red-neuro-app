import 'package:flutter/material.dart';
import 'componentes/bottom_nav_bar.dart';

class MaquinariaScreen extends StatelessWidget {
  const MaquinariaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DS2243 Maquinaria')),
      body: const Center(
        child: Text(
          'Pantalla de DS2243 Maquinaria',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
    );
  }
}
