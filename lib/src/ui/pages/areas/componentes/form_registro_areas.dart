import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/models/area.dart';
import 'package:camino_seguro/src/ui/common/buttons/simple_button.dart';
import 'package:camino_seguro/src/ui/common/components/bottom_navigation.dart';
import 'package:camino_seguro/src/ui/common/components/custom_title.dart';
import 'package:camino_seguro/src/ui/common/snackbar/snackbar.dart';
import 'package:camino_seguro/src/ui/pages/areas/screens/areas.dart';
import 'package:camino_seguro/src/ui/pages/areas/services/areas_service.dart';
import 'package:camino_seguro/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class FormAreas extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final Area? areaEditar;

  const FormAreas({
    super.key,
    required this.titulo,
    required this.descripcion,
    this.areaEditar,
  });

  @override
  State<FormAreas> createState() => _FormAreas();
}

class _FormAreas extends State<FormAreas> {
  late AreasService service;
  final RegistroAreasStore store = RegistroAreasStore.instance;
  final TextEditingController nombreArea = TextEditingController();
  late int _currentStep;

  late List<LatLng> puntosRuta;
  List<LatLng> puntosArea = [];
  List<LatLng> rutaCalculada = [];

  @override
  void initState() {
    super.initState();
    service = AreasService('', context);
    _currentStep = widget.areaEditar != null ? 1 : 0;
    nombreArea.text = widget.areaEditar?.nombre ?? '';

    puntosRuta = widget.areaEditar?.ruta.coordinates
            .map((e) => LatLng(e[1], e[0]))
            .toList() ??
        [];
    rutaCalculada = puntosRuta.isNotEmpty ? puntosRuta : [];

    puntosArea = widget.areaEditar?.geometria.coordinates.isNotEmpty == true
        ? widget.areaEditar!.geometria.coordinates[0]
            .map((e) => LatLng(e[1], e[0]))
            .toList()
        : [];
  }

  void _siguientePaso() async {
    if (_currentStep == 0 && puntosRuta.length >= 2) {
      final nuevaRuta = await service.calcularRuta(puntosRuta);
      setState(() {
        rutaCalculada = nuevaRuta;
        _currentStep = 1;
      });
    }
  }

  void _anteriorPaso() {
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        puntosArea.clear();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _guardarArea() {
    if (nombreArea.text.trim().isNotEmpty &&
        puntosArea.length >= 3 &&
        puntosRuta.length >= 2) {
      final nombre = nombreArea.text.trim();

      final geometria = puntosArea
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();

      final ruta = puntosRuta
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();

      service.registrarArea(
        context,
        nombre,
        ruta,
        geometria,
        widget.areaEditar?.id,
      );
    } else {
      showSnackBar(
        areasMessenger,
        'Debe ingresar nombre, al menos 2 puntos de ruta y 3 del área',
        state: StatusSnackBar.warning,
      );
    }
  }

  Widget _mapaAreaWidget() {
    final puntos = _currentStep == 0 ? puntosRuta : puntosArea;

    return Expanded(
      child: FlutterMap(
        options: MapOptions(
          initialCenter:
              puntos.isNotEmpty ? puntos.first : const LatLng(-16.5, -68.15),
          initialZoom: 15.0,
          onTap: (_, latlng) {
            setState(() {
              puntos.add(latlng);
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          if (rutaCalculada.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: rutaCalculada,
                  strokeWidth: 4.0,
                  color: Colors.green,
                ),
              ],
            ),
          if (_currentStep == 1 && puntosArea.length >= 2)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: puntosArea,
                  color: Colors.orange.withAlpha(100),
                  borderStrokeWidth: 3,
                  borderColor: Colors.red,
                ),
              ],
            ),
          MarkerLayer(
            markers: puntos.asMap().entries.map((entry) {
              final index = entry.key;
              final punto = entry.value;
              return Marker(
                point: punto,
                width: 30,
                height: 30,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      puntos.removeAt(index);
                      if (_currentStep == 0) rutaCalculada.clear();
                    });
                  },
                  child: const Icon(Icons.location_on,
                      size: 24, color: Colors.red),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Consumer<RegistroAreasStore>(
      builder: (context, store, child) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTitle(
                  title: widget.titulo,
                  icon: Icons.map,
                  color: theme.secondary,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(widget.descripcion, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                if (_currentStep == 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: nombreArea,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Área',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                _mapaAreaWidget(),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigation(
            button1: SimpleButton(
              title: _currentStep == 0 ? 'Calcular Ruta' : 'Guardar Área',
              onTap: _currentStep == 0 ? _siguientePaso : _guardarArea,
            ),
            button2: SimpleButton(
              title: _currentStep == 0
                  ? 'Cancelar'
                  : widget.areaEditar != null
                      ? 'Volver a calcular ruta'
                      : 'Volver al Paso Anterior',
              onTap: _anteriorPaso,
              outlined: true,
              background: theme.secondary,
              textColor: theme.black,
            ),
          ),
        );
      },
    );
  }
}
