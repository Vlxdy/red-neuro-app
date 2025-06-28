import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/models/area.dart';
import 'package:camino_seguro/src/models/dependiente.dart';
import 'package:camino_seguro/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/services/dependientes.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/stores/registro_dependientes_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> ubicacionesMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Ubicaciones extends StatefulWidget {
  const Ubicaciones({super.key});

  @override
  State<Ubicaciones> createState() => UbicacionesScreen();
}

class UbicacionesScreen extends State<Ubicaciones> {
  late DependientesService dependientesService;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    dependientesService = DependientesService.named('', context);
    _refresh(_selectedDate);
  }

  Future<void> _refresh(DateTime? selectedDate) async {
    await dependientesService.fetchData(selectedDate);
  }

  Color parseColor(dynamic colorValue) {
    if (colorValue is Color) return colorValue;
    if (colorValue is String) {
      var hex = colorValue.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    }
    return Colors.black;
  }

  Color colorFromText(String input) {
    final int hash = input.hashCode;
    final double hue = (hash & 0xFFFFFFFF) % 360;
    final hsl = HSLColor.fromAHSL(1.0, hue, 0.6, 0.5);
    return hsl.toColor();
  }

  Widget _mapaUbicacionesWidget(
      List<Area> areas, List<DependienteRuta> rutasDeHoy) {
    final polygons = <Polygon>[];
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    for (final dep in rutasDeHoy) {
      if (dep.rutadeHoy.coordinates.isNotEmpty) {
        final routePoints =
            dep.rutadeHoy.coordinates.map((c) => LatLng(c[1], c[0])).toList();

        final routeColor = colorFromText(dep.nombre);

        polylines.add(Polyline(
          points: routePoints,
          color: routeColor,
          strokeWidth: 6.0,
          isDotted: true,
        ));

        final last = routePoints.last;
        markers.add(Marker(
          point: last,
          width: 80,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 36, color: routeColor),
              const SizedBox(height: 4),
              Container(
                color: Colors.white,
                child: Text(
                  dep.nombre,
                  style: TextStyle(fontSize: 14, color: routeColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ));
      }
    }

    for (final area in areas) {
      for (final poly in area.geometria.coordinates) {
        final pts = poly.map((c) => LatLng(c[1], c[0])).toList();
        polygons.add(Polygon(
          points: pts,
          color: colorFromText(area.nombre).withAlpha(50),
          borderColor: colorFromText(area.nombre),
          borderStrokeWidth: 1,
          isFilled: true,
        ));
      }
      if (area.ruta.coordinates.isNotEmpty) {
        final pts =
            area.ruta.coordinates.map((c) => LatLng(c[1], c[0])).toList();
        polylines.add(Polyline(
          points: pts,
          color: colorFromText(area.nombre),
          strokeWidth: 3,
        ));
      }
    }

    return Expanded(
      child: Stack(children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-16.5, -68.15),
            initialZoom: 14.0,
            interactionOptions:
                InteractionOptions(flags: ~InteractiveFlag.doubleTapZoom),
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
            ),
            if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_outlined, color: Colors.blue),
                  onPressed: () {
                    _refresh(_selectedDate);
                  },
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        _selectedDate = selectedDate;
                      });
                      _refresh(selectedDate);
                    }
                  },
                  child: Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}\nSeleccionar Fecha',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                    _refresh(_selectedDate);
                  },
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Consumer<RegistroAreasStore>(
      builder: (context, store, child) {
        return ScaffoldMessenger(
          key: ubicacionesMessenger,
          child: RefreshIndicator(
            onRefresh: () => _refresh(_selectedDate),
            child: Scaffold(
              backgroundColor: parseColor(theme.background),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.map,
                            size: 28, color: parseColor(theme.primary)),
                        const SizedBox(width: 8),
                        Text(
                          'Ubicaciones',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: parseColor(theme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<RegistroDependientesStore>(
                      builder: (context, dependientesStore, _) {
                        return _mapaUbicacionesWidget(
                          store.listaAreas,
                          dependientesStore.listaDependientesRuta,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
