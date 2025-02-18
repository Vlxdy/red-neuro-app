import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:flutter/material.dart';
import 'usuario_directo_paso2_screen.dart';

class UsuarioDirectoPaso3Screen extends StatefulWidget {
  const UsuarioDirectoPaso3Screen({Key? key}) : super(key: key);

  @override
  _UsuarioDirectoPaso3ScreenState createState() =>
      _UsuarioDirectoPaso3ScreenState();
}

class _UsuarioDirectoPaso3ScreenState extends State<UsuarioDirectoPaso3Screen> {
  final theme = ThemeController.instance;
  List<Map<String, String>> autorizaciones = [
    {
      'codigo': 'ABC123',
      'combustible': 'Diesel',
      'volumen': '500',
      'placa': '546PYP',
      'observacion': 'El volumen vendido superó al volumen autorizado',
    }
  ];

  void _agregarAutorizacion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Función de agregar autorización no implementada')),
    );
  }

  void _eliminarAutorizacion(int index) {
    setState(() {
      autorizaciones.removeAt(index);
    });
  }

  void _finalizarProceso() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proceso finalizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.bgBlue),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_gas_station, color: theme.bgBlue, size: 28),
                SizedBox(width: 8),
                Text(
                  'Venta de combustible a\nUSUARIOS DIRECTOS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.bgBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Registrarás una nueva venta de combustible',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const Text(
              'Paso 3 de 3',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Autorizaciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _agregarAutorizacion,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.teal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add, color: Colors.teal),
                    label: const Text('Agregar autorización'),
                  ),
                  const SizedBox(height: 8),
                  if (autorizaciones.isNotEmpty)
                    Column(
                      children: List.generate(autorizaciones.length, (index) {
                        var autorizacion = autorizaciones[index];
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow('Cód. autorización',
                                          autorizacion['codigo']!),
                                      _buildInfoRow('Tipo combustible',
                                          autorizacion['combustible']!),
                                      _buildInfoRow(
                                          'Volumen', autorizacion['volumen']!),
                                      _buildInfoRow('Nro. de Placa',
                                          autorizacion['placa']!),
                                      const Text(
                                        'Observación',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                      Text(
                                        autorizacion['observacion']!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.grey),
                                  onPressed: () => _eliminarAutorizacion(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _finalizarProceso,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.bgBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Finalizar'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UsuarioDirectoPaso2Screen()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.bgBlue,
                side: BorderSide(color: theme.bgBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: Icon(Icons.arrow_back, color: theme.bgBlue),
              label: const Text('Anterior'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.bgBlue,
                side: BorderSide(color: theme.bgBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: Icon(Icons.cancel, color: theme.bgBlue),
              label: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
