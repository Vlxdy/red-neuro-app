import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/models/resumen_dia.dart';
import 'package:control_ventas_movil/src/ui/pages/inicio/inicio_store.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/componentes/venta_card.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia_service.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> inicioMessenger =
    GlobalKey<ScaffoldMessengerState>();

class ResumenDelDiaPage extends StatefulWidget {
  const ResumenDelDiaPage({super.key});

  @override
  State<ResumenDelDiaPage> createState() => _ResumenDelDiaPageState();
}

class _ResumenDelDiaPageState extends State<ResumenDelDiaPage>
    with WidgetsBindingObserver {
  late ResumenDiaService service;
  final pinStore = CodigoPinStore.instance;

  @override
  void initState() {
    service = ResumenDiaService('', context);
    service.fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final resumenDia = context.watch<ResumenDiaStore>().resumenDia;

    return ScaffoldMessenger(
      key: inicioMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(children: [
                Icon(Icons.stacked_bar_chart, color: theme.primary, size: 30),
                const SizedBox(width: 8),
                Text(
                  'Resumen del día',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25))),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                      ...resumenDia!.ventas.map((venta) => VentaCard(
                            theme: ThemeController.instance,
                            iconData: Icons.import_contacts,
                            titulo: venta.tipoVenta,
                            combustibles: Map.fromEntries(venta.detalle.map(
                              (combustible) => MapEntry(
                                  combustible.tipoCombustible,
                                  combustible.cantidad),
                            )),
                            total: '10,000',
                          )),
                      VentaCard(
                        theme: ThemeController.instance,
                        iconData: Icons.import_contacts,
                        titulo: 'Bidones',
                        combustibles: const {
                          'Gasolina': '5000L',
                          'Diesel': '3000L',
                          'Diesel6': '4000L',
                          'Super': '2000L',
                          'Premium': '1000L',
                          'Extra': '1500L',
                        },
                        total: '10,000',
                      ),
                      VentaCard(
                        theme: ThemeController.instance,
                        iconData: Icons.motorcycle,
                        titulo: 'Maquinaria',
                        combustibles: const {
                          'Gasolina': '5000L',
                          'Diesel': '3000L',
                          'Diesel6': '4000L',
                          'Super': '2000L',
                          'Premium': '1000L',
                          'Extra': '1500L',
                        },
                        total: '10,000',
                      ),
                      VentaCard(
                        theme: ThemeController.instance,
                        iconData: Icons.nature_people,
                        titulo: 'Usuarios Directos',
                        combustibles: const {
                          'Gasolina': '5000L',
                          'Diesel': '3000L',
                          'Diesel6': '4000L',
                          'Super': '2000L',
                          'Premium': '1000L',
                          'Extra': '1500L',
                        },
                        total: '10,000',
                      ),
                      VentaCard(
                        theme: ThemeController.instance,
                        iconData: Icons.local_gas_station,
                        titulo: 'Tanque Adicional',
                        combustibles: const {
                          'Gasolina': '5000L',
                          'Diesel': '3000L',
                          'Diesel6': '4000L',
                          'Super': '2000L',
                          'Premium': '1000L',
                          'Extra': '1500L',
                        },
                        total: '10,000',
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
                      const SizedBox(height: 8),
                      ...resumenDia.volumenes.expand(
                        (volumen) => volumen.tanqueRegistroVolumen.map(
                          (tanque) => _buildVolumenItem(
                            theme,
                            hora: tanque.hora,
                            tanque: tanque.nombre,
                            combustible: tanque.tipoCombustible,
                            volumen: tanque.volumen,
                          ),
                        ),
                      ),
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
                        cantidad: resumenDia.novedades?.totalObservaciones
                                .toString() ??
                            "0",
                      ),
                      _buildNovedadItem(
                        theme,
                        iconData: Icons.warning,
                        titulo: 'Incidentes',
                        cantidad:
                            resumenDia.novedades?.totalIncidentes.toString() ??
                                "0",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )),
      ),
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
            _buildChip(theme, label: combustible, color: theme.background),
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
