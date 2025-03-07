import 'package:collection/collection.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/enums.dart';
import 'package:control_ventas_movil/src/ui/pages/inicio/inicio_store.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/componentes/venta_card.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia_service.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common/components/skeleton.dart';

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    service = ResumenDiaService('', context);
    _loadData();
  }

  Future<void> _loadData() async {
    await service.fetchData();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      isLoading = true;
    });
    service = ResumenDiaService('', context);
    await service.fetchData();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final resumenDia = context.watch<ResumenDiaStore>().resumenDia;
    IconData icono(String tipoVenta) {
      TipoVentas? tipo = TipoVentas.values.firstWhereOrNull(
        (e) => e.descripcion == tipoVenta,
      );
      if (tipo == null) return Icons.info;
      switch (tipo) {
        case TipoVentas.bidones:
          return Icons.import_contacts;
        case TipoVentas.maquinarias:
          return Icons.motorcycle;
        case TipoVentas.tanqueAdicional:
          return Icons.nature_people;
        case TipoVentas.usuariosDirectos:
          return Icons.local_gas_station;
      }
    }

    return ScaffoldMessenger(
        key: inicioMessenger,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Scaffold(
            backgroundColor: theme.background,
            body: SafeArea(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: isLoading
                  ? [const SkeletonGrid(rows: 5, columns: 1, itemHeight: 30)]
                  : [
                      const SizedBox(height: 15),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(children: [
                          Icon(Icons.stacked_bar_chart,
                              color: theme.primary, size: 30),
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
                                    color: theme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...resumenDia.ventas.map((venta) => VentaCard(
                                      theme: ThemeController.instance,
                                      iconData: icono(venta.tipoVenta),
                                      titulo: venta.tipoVenta,
                                      combustibles: venta.detalle,
                                      total: venta.cantidad,
                                    )),
                                const SizedBox(height: 16),
                                Text(
                                  'Volúmenes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const SizedBox(height: 8),
                                ...resumenDia.volumenes.expand(
                                  (volumen) =>
                                      volumen.tanqueRegistroVolumen.map(
                                    (tanque) => _buildVolumenItem(
                                      theme,
                                      hora: DateFormat('HH:mm')
                                          .format(DateTime.parse(tanque.hora)),
                                      tanque: volumen.nombre,
                                      combustible: tanque.combustible!.codigo,
                                      volumen: tanque.volumen,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Novedades',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildNovedadItem(
                                  theme,
                                  iconData: Icons.info,
                                  titulo: 'Observaciones',
                                  cantidad: resumenDia
                                          .novedades?.totalObservaciones
                                          .toString() ??
                                      "0",
                                ),
                                _buildNovedadItem(
                                  theme,
                                  iconData: Icons.warning,
                                  titulo: 'Incidentes',
                                  cantidad: resumenDia
                                          .novedades?.totalIncidentes
                                          .toString() ??
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
        ));
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
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ListTile(
        leading: Text(
          hora,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: theme.secondary,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tanque,
              style: TextStyle(
                color: theme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            _buildChip(theme, label: combustible, color: theme.primary),
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
        leading: Icon(iconData, color: theme.secondary),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.secondary,
          ),
        ),
        trailing: Text(
          cantidad,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ThemeController theme,
      {required String label, required Color color}) {
    return Chip(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: theme.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }
}
