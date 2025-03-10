import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/common/selector_image/multiple_campo_fotografia.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/tanque_confirmar_registro_venta.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/stores/registrar_venta_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegistarVentaTanque extends StatefulWidget {
  final String tipoCombustible;
  const RegistarVentaTanque({Key? key, this.tipoCombustible = 'Diesel'})
      : super(key: key);

  @override
  State<RegistarVentaTanque> createState() => _RegistarVentaTanqueState();
}

class _RegistarVentaTanqueState extends State<RegistarVentaTanque> {
  final _placaController = TextEditingController();
  final List<String> _fotos = [];

  bool _agregarObs = false;
  String _observacion = '';
  final theme = ThemeController.instance;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RegistrarVentaStore>();


    return Scaffold(
      backgroundColor: theme.white,
      appBar: AppBar(
        backgroundColor: theme.white,
        title: Text(
          'Venta de ${widget.tipoCombustible} a vehículos\ncon TANQUE ADICIONALL',
          style: TextStyle(fontSize: 16, color: theme.secondary),
        ),
        leading: Icon(Icons.local_gas_station, color: theme.secondary,),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registrarás una nueva venta de ${widget.tipoCombustible.toUpperCase()}',
                      style: TextStyle(fontSize: 14, color: theme.grey),
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
                    MultipleCampoFotografia(
                      titulo: 'Fotografías',
                      paths: store.fotos,
                      onClick: (path) => store.fotos = path,
                      onDelete: (index) => store.eliminarFoto(index),
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
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ConfirmarRegistroScreen(
                              placa: _placaController.text, numeroFotos: 2)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary,
                    foregroundColor: theme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Siguiente'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.secondary,
                    side: BorderSide(color: theme.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: Icon(Icons.cancel, color: theme.secondary),
                  label: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ],
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
                    icon: Icon(Icons.delete, color: theme.error),
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
        Text(
          'Toma fotografías de la placa y del tanque adicional del vehículo',
          style: TextStyle(fontSize: 12, color: theme.grey),
        ),
      ],
    );
  }
}
