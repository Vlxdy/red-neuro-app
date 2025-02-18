import 'package:flutter/material.dart';

import 'usuario_directo_screen.dart';
import '../venta_bidones_screen.dart';
import '../maquinaria_screen.dart';
import '../tanque_adicional.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const BottomNavBar({Key? key, required this.selectedIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen =  VentaBidonesScreen();
        break;
      case 1:
        nextScreen =  MaquinariaScreen();
        break;
      case 2:
        nextScreen =  UsuarioDirectoScreen();
        break;
      case 3:
        nextScreen = const TanqueAdicionalScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.local_gas_station),
          label: 'Venta en Bidones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.agriculture),
          label: 'Maquinaria',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Usuario Directo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_gas_station_outlined),
          label: 'Tanque adicional',
        ),
      ],
    );
  }
}
