import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_service.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_store.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> inicioMessenger =
    GlobalKey<ScaffoldMessengerState>();

class InicioPage extends StatefulWidget {
  final VoidCallback onGoVehicles;
  const InicioPage({super.key, required this.onGoVehicles});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> with WidgetsBindingObserver {
  late InicioService service;
  final CodigoPinStore pinStore = CodigoPinStore.instance;

  @override
  void initState() {
    super.initState();
    service = InicioService('', context);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.brightness,
      builder: (BuildContext context, bool _, Widget? child) {
        final ThemeController theme = ThemeController.instance;
        return ScaffoldMessenger(
          key: inicioMessenger,
          child: Scaffold(
            backgroundColor: theme.background,
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 15),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.stacked_bar_chart,
                          color: theme.primary,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resumen del día',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            const SizedBox(height: 25),
                            Text(
                              'Ventas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.success,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      color: theme.bgCard,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(
          hora,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.fontColor,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _buildChip(theme, label: combustible, color: theme.secondary),
            const SizedBox(width: 8),
            Text(
              tanque,
              style: TextStyle(
                color: theme.fontColor,
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
            color: theme.fontColor,
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
      color: theme.bgCard,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(iconData, color: theme.primary),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.fontColor,
          ),
        ),
        trailing: Text(
          cantidad,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.fontColor,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    ThemeController theme, {
    required String label,
    required Color color,
  }) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: theme.calculateTextColor(color),
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
    );
  }
}
