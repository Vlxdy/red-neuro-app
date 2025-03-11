import 'package:control_ventas_movil/src/models/combustible.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/combustibles_store.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/combustible_card.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/services/venta_bidones_service.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/stores/venta_bidones_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:control_ventas_movil/src/config/theme_controller.dart';

class VentaBidonesScreen extends StatefulWidget {
  const VentaBidonesScreen({Key? key}) : super(key: key);

  @override
  State<VentaBidonesScreen> createState() => _VentaBidonesScreenState();
}

class _VentaBidonesScreenState extends State<VentaBidonesScreen> {
  final theme = ThemeController.instance;
  late VentaBidonesService _service;

  @override
  void initState() {
    _service = VentaBidonesService('', context);
    _service.fetchDataBidones();
    super.initState();
  }

  Future<void> _refreshList() async {
    _service.cargarVentasBidones();
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final store = context.watch<VentaBidonesStore>();

    List<Combustible> listaCombustibles = CombustiblesStore.instance.combustibles;
    return ScaffoldMessenger(
      key: bidonesMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Venta de Bidones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshList,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: store.cargando
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                    onRefresh: _refreshList,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisExtent: 200,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: store.ventas.length,
                      itemBuilder: (context, index) {
                        final venta = store.ventas[index];
                        Combustible combustible = listaCombustibles.firstWhere(
                              (c) => c.codigo == venta.codigo,
                          orElse: () => Combustible.empty,
                        );
                        return CombustibleCard(
                          title: combustible.nombre!,
                          ventasRegistradas: venta.cantidadVentas,
                          color: (index + 1) % 4 == 1 || (index + 1) % 4 == 0 ? theme.primary : theme.secondary ,
                          onPressedNuevaVenta: () {
                            _mostrarDialogoRegistro(combustible.id);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoRegistro(String idCombustible) {
    bool agregarObservacion = false;
    TextEditingController observacionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Registrar nueva venta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿Deseas registrar una nueva venta?'),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Agregar una observación'),
                    value: agregarObservacion,
                    onChanged: (bool? value) {
                      setStateDialog(() {
                        agregarObservacion = value ?? false;
                      });
                    },
                  ),
                  if (agregarObservacion)
                    TextField(
                      controller: observacionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Escribe una observación...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _service.incrementarVenta(idCombustible, observacionController.text);
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
