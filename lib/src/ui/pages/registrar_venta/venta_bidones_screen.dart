import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
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
                  ),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'EESS Santa Rosa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '12/12/2024 00:00 - 08:00',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
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

            Row(
              children: [
                Expanded(
                  child: _FuelCard(
                    title: 'Diesel',
                    ventasRegistradas: ventasDiesel,
                    color: theme.bgBlue,
                    icon: Icons.oil_barrel,
                    onPressedNuevaVenta: _incrementarDiesel,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FuelCard(
                    title: 'Gasolina especial',
                    ventasRegistradas: ventasGasolina,
                    color: Colors.teal,
                    icon: Icons.local_gas_station,
                    onPressedNuevaVenta: _incrementarGasolina,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
    );
  }
}

class _FuelCard extends StatelessWidget {
  final String title;
  final int ventasRegistradas;
  final Color color;
  final IconData icon;
  final VoidCallback onPressedNuevaVenta;

  const _FuelCard({
    Key? key,
    required this.title,
    required this.ventasRegistradas,
    required this.color,
    required this.icon,
    required this.onPressedNuevaVenta,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ventas registradas',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              ventasRegistradas.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onPressedNuevaVenta,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: Text('Nueva venta ${title.toUpperCase()}'),
            ),
          ],
        ),
      ),
    );
  }
}
