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

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<VentaBidonesStore>(context);

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
                Text(
                  'Venta de Bidones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                store.cargando
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                  child: ListView.builder(
                    itemCount: store.ventas.length,
                    itemBuilder: (context, index) {
                      final venta = store.ventas[index];
                      return Card(
                        child: ListTile(
                          title: Text(venta.codigo),
                          subtitle: Text(
                            'Cantidad vendida: ${venta.cantidadVentas}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              _mostrarDialogoRegistro(venta.codigo);
                            },
                          ),
                        ),
                      );
                    },
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
                    Navigator.pop(context); // Cierra el diálogo
                    _service.incrementarVenta(idCombustible);
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeController.instance.primary,
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
