import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';

class ResumenDelDiaPage extends StatelessWidget {
  const ResumenDelDiaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

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
                  _buildVentaItem(
                    theme,
                    iconData: Icons.local_drink,
                    titulo: 'Bidones',
                    gasolina: 'G12',
                    diesel: 'D8',
                    total: '20',
                  ),
                  _buildVentaItem(
                    theme,
                    iconData: Icons.agriculture,
                    titulo: 'Maquinaria',
                    gasolina: 'G0',
                    diesel: 'D12',
                    total: '12',
                  ),
                  _buildVentaItem(
                    theme,
                    iconData: Icons.home_work,
                    titulo: 'Usuarios directos',
                    gasolina: 'G0',
                    diesel: 'D4',
                    total: '4',
                  ),
                  _buildVentaItem(
                    theme,
                    iconData: Icons.local_gas_station,
                    titulo: 'Tanque adicional',
                    gasolina: 'G0',
                    diesel: 'D2',
                    total: '2',
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Volúmenes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.background,
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
                      color: theme.background,
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

          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: theme.primary,
            unselectedItemColor: theme.black,
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
            // onTap: (index) { ... }
          ),
        ),
      ),
    );
  }

  Widget _buildVentaItem(
      ThemeController theme, {
        required IconData iconData,
        required String titulo,
        required String gasolina,
        required String diesel,
        required String total,
      }) {
    return Card(
      elevation: 1,
      color: theme.accent900,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.primary.withOpacity(0.2),
          child: Icon(iconData, color: theme.primary),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.background,
          ),
        ),
        subtitle: Row(
          children: [
            _buildChip(theme, label: 'G $gasolina', color: theme.primary),
            const SizedBox(width: 8),
            _buildChip(theme, label: 'D $diesel', color: theme.secondary),
          ],
        ),
        trailing: Text(
          total,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.background,
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
            color: theme.background,
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
                color: theme.background,
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
            color: theme.background,
          ),
        ),
        trailing: Text(
          cantidad,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.background,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ThemeController theme, {required String label, required Color color}) {
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
