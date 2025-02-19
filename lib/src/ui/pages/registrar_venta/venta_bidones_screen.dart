import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/combustible_card.dart';
import 'package:flutter/material.dart';

class VentaBidonesScreen extends StatefulWidget {
  const VentaBidonesScreen({Key? key}) : super(key: key);

  @override
  _VentaBidonesScreenState createState() => _VentaBidonesScreenState();
}

class _VentaBidonesScreenState extends State<VentaBidonesScreen> {
  int ventasDiesel = 12;
  int ventasGasolina = 22;

  final theme = ThemeController.instance;

  void _mostrarDialogoRegistro(String combustible, VoidCallback onConfirm) {
    bool agregarObservacion = false;
    TextEditingController observacionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Registrar nueva venta de $combustible',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      setState(() {
                        agregarObservacion = value ?? false;
                      });
                    },
                  ),
                  if (agregarObservacion)
                    TextField(
                      controller: observacionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Escribe una observación...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Cancelar',
                      style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    onConfirm();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _incrementarDiesel() {
    _mostrarDialogoRegistro('Diesel', () {
      setState(() {
        ventasDiesel++;
      });
    });
  }

  void _incrementarGasolina() {
    _mostrarDialogoRegistro('Gasolina', () {
      setState(() {
        ventasGasolina++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.local_gas_station, color: Colors.teal, size: 28),
                SizedBox(width: 8),
                Text(
                  'Bidones',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const Text(
              'Venta de Combustible en bidones',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisExtent: 200,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              children: [
                CombustibleCard(
                  title: 'Diesel',
                  ventasRegistradas: ventasDiesel,
                  color: theme.bgBlue,
                  onPressedNuevaVenta: _incrementarDiesel,
                ),
                CombustibleCard(
                  title: 'GASOLINA ULTRA PREMIUM 100',
                  ventasRegistradas: ventasGasolina,
                  color: Colors.teal,
                  onPressedNuevaVenta: _incrementarGasolina,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
