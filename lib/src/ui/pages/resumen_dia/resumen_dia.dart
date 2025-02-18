import 'package:control_ventas_movil/src/ui/pages/registrar_venta/tanque_adicional.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/meters_mangueras.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';

import 'componentes/venta_card.dart';

class ResumenDelDiaPage extends StatefulWidget {
  const ResumenDelDiaPage({Key? key}) : super(key: key);

  @override
  _ResumenDelDiaPageState createState() => _ResumenDelDiaPageState();
}

class _ResumenDelDiaPageState extends State<ResumenDelDiaPage> {
  int _selectedIndex = 0;
  bool showSubNav = false;
  final theme = ThemeController.instance;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      showSubNav = index == 2
          ? showSubNav
              ? false
              : true
          : false;
    });
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResumenDelDiaPage()),
        );
        break;
      case 1:
        break;
      case 2:
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const TanqueAdicionalScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePage(
      page: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EESS Santa Rosa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primary200,
                        ),
                      ),
                      Text(
                        '12/12/2024 00:00 - 08:00',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.primary200.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Resumen del día',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primary200,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ventas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  VentaCard(
                    theme: ThemeController.instance,
                    iconData: Icons.local_gas_station,
                    titulo: 'Ventas de Combustible',
                    combustibles: {
                      'Gasolina': '5000L',
                      'Diesel': '3000L',
                      'Diesel6': '4000L',
                      'Super': '2000L',
                      'Premium': '1000L',
                      'Extra': '1500L',
                    },
                    total: '\$10,000',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Volúmenes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildVolumenItem(
                    theme,
                    hora: '08:20',
                    tanque: 'Tanque 1',
                    combustible: 'DO',
                    volumen: '23000',
                  ),
                  _buildVolumenItem(
                    theme,
                    hora: '08:10',
                    tanque: 'Tanque 2',
                    combustible: 'GE',
                    volumen: '20000',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Novedades',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNovedadItem(
                    theme,
                    iconData: Icons.info,
                    titulo: 'Observaciones',
                    cantidad: '3',
                  ),
                  _buildNovedadItem(
                    theme,
                    iconData: Icons.warning,
                    titulo: 'Incidentes',
                    cantidad: '1',
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSubNav)
                Container(
                  color: Colors.teal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const VolumenesTanquesScreen()),
                          );
                        },
                        icon: const Icon(Icons.local_gas_station,
                            color: Colors.white),
                        label: const Text('Volúmenes Tanques',
                            style: TextStyle(color: Colors.white)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const MetersManguerasScreen()),
                          );
                        },
                        icon: const Icon(Icons.speed, color: Colors.white),
                        label: const Text('Contadores Mangueras',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.black,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                    label: 'Resumen del día',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sync),
                    label: 'Sincronizar Reportes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.speed),
                    label: 'Volúmenes y contadores',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart),
                    label: 'Registrar Ventas',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumenItem(
    ThemeController theme, {
    required String hora,
    required String tanque,
    required String combustible,
    required String volumen,
  }) {
    return Card(
      elevation: 1,
      color: theme.accent900,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(
          hora,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.primary,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildChip(theme, label: combustible, color: theme.secondary),
            const SizedBox(width: 8),
            Text(
              tanque,
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Text(
          volumen,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildNovedadItem(
    ThemeController theme, {
    required IconData iconData,
    required String titulo,
    required String cantidad,
  }) {
    return Card(
      elevation: 1,
      color: theme.success,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(iconData, color: theme.primary),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.primary,
          ),
        ),
        trailing: Text(
          cantidad,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ThemeController theme,
      {required String label, required Color color}) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: theme.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
    );
  }
}
