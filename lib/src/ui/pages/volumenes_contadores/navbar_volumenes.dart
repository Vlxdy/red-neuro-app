import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/meters_mangueras.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques.dart';
import 'package:flutter/material.dart';

class NavBarVolumenes extends StatelessWidget {
  final int selectedIndex;

  const NavBarVolumenes({super.key, required this.selectedIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const VolumenesTanquesScreen();
        break;
      case 1:
        nextScreen = const MetersManguerasScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    assert(0 <= selectedIndex && selectedIndex < 2,
        'selectedIndex must be between 0 and 1');
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      selectedItemColor: theme.primary,
      unselectedItemColor:
          const Color.from(alpha: 1, red: 0.62, green: 0.62, blue: 0.62),
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.local_gas_station),
          label: 'Volúmenes Tanques',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.speed),
          label: 'Cantidad Mangueras',
        ),
      ],
    );
  }
}
