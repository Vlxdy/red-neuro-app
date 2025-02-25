import 'package:flutter/material.dart';

class MaquinariaScreen extends StatelessWidget {
  const MaquinariaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Pantalla de DS2243 Maquinaria',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
