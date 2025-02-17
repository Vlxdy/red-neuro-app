import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/confirmar_registro.dart';
import 'package:flutter/material.dart';

class NuevaVentaScreen extends StatefulWidget {
  final String tipoCombustible;
  const NuevaVentaScreen({Key? key, this.tipoCombustible = 'Diesel'})
      : super(key: key);

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final _placaController = TextEditingController();
  final List<String> _fotos = [];

  bool _agregarObs = false;
  String _observacion = '';

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final bool esDiesel = widget.tipoCombustible.toLowerCase() == 'diesel';
    final colorPrincipal = esDiesel ? theme.bgBlue : Colors.teal;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorPrincipal,
        title: Text(
          'Venta de ${widget.tipoCombustible} a vehículos\ncon TANQUE ADICIONAL',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrarás una nueva venta de ${widget.tipoCombustible.toUpperCase()}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _placaController,
              decoration: const InputDecoration(
                labelText: 'Nro. de Placa de vehículo',
                hintText: 'Ej. 5461PYP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fotografías',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPhotoSection(),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _agregarObs,
                  onChanged: (value) {
                    setState(() {
                      _agregarObs = value ?? false;
                      if (!_agregarObs) _observacion = '';
                    });
                  },
                ),
                const Text('Agregar una observación'),
              ],
            ),
            if (_agregarObs) ...[
              TextField(
                onChanged: (value) => _observacion = value,
                decoration: const InputDecoration(
                  labelText: 'Observación',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrincipal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ConfirmarRegistroScreen(placa: _placaController.text, numeroFotos: 2)),
                    );
                  },
                  child: const Text('Siguiente  →'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_fotos.isNotEmpty)
          Wrap(
            spacing: 8.0,
            children: _fotos.map((foto) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.network(
                    foto,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _fotos.remove(foto);
                      });
                    },
                  ),
                ],
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {

          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('Tomar foto'),
        ),
        const SizedBox(height: 4),
        const Text(
          'Toma fotografías de la placa y del tanque adicional del vehículo',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
