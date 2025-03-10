import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/combustible_card.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/tanque_registrar_venta.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/services/venta_tanque_service.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/stores/venta_tanques_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VentaTanquesScreen extends StatefulWidget {
  const VentaTanquesScreen({Key? key}) : super(key: key);

  @override
  State<VentaTanquesScreen> createState() => _VentaTanquesScreenState();
}

class _VentaTanquesScreenState extends State<VentaTanquesScreen> {
  final theme = ThemeController.instance;
  late VentaTanquesService _service;

  @override
  void initState() {
    _service = VentaTanquesService('', context);
    _service.fetchDataTanques();
    super.initState();
  }

  Future<void> _refreshList() async {
    await _service.cargarVentasTanques();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<VentaTanquesStore>(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_gas_station, color: theme.primary, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Tanque adicional',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _refreshList,
                  ),
                ],
              ),
              Text(
                'Venta de combustible a vehículos con DOBLE TANQUE',
                style: TextStyle(fontSize: 14, color: theme.primary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshList,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisExtent: 200,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: store.ventas.length,
                      itemBuilder: (context, index) {
                        final venta = store.ventas[index];
                        return CombustibleCard(
                          title: venta.codigo,
                          ventasRegistradas: venta.cantidadVentas,
                          color: index.isEven ? theme.primary : theme.secondary,
                          onPressedNuevaVenta: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistarVentaTanque(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
