import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:flutter/material.dart';
import 'usuario_directo_paso3_screen.dart';

class UsuarioDirectoPaso2Screen extends StatefulWidget {
  const UsuarioDirectoPaso2Screen({Key? key}) : super(key: key);

  @override
  _UsuarioDirectoPaso2ScreenState createState() =>
      _UsuarioDirectoPaso2ScreenState();
}

class _UsuarioDirectoPaso2ScreenState extends State<UsuarioDirectoPaso2Screen> {
  final theme = ThemeController.instance;
  void _mostrarModalAgregarAutorizacion() {
    String? tipoCombustible = 'Diesel Oil';
    TextEditingController codigoController = TextEditingController();
    TextEditingController volumenController = TextEditingController();
    TextEditingController observacionController = TextEditingController();
    bool agregarObservacion = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.receipt, color: theme.bgBlue),
                  SizedBox(width: 8),
                  Text(
                    'Agregar autorización',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tipo de combustible',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: tipoCombustible,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      items: ['Diesel Oil', 'Gasolina Especial', 'GLP']
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          tipoCombustible = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Código de autorización',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: codigoController,
                      decoration: InputDecoration(
                        hintText: 'Ej. ABC123',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Volumen',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: volumenController,
                      decoration: InputDecoration(
                        hintText: 'Ej. 50',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Agregar una observación'),
                      value: agregarObservacion,
                      onChanged: (bool? value) {
                        setState(() {
                          agregarObservacion = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Autorización agregada')),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.bgBlue,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _siguientePaso() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const UsuarioDirectoPaso3Screen()),
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
              'Paso 2 de 3',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Autorizaciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _mostrarModalAgregarAutorizacion,
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
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _siguientePaso,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.bgBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }
}
