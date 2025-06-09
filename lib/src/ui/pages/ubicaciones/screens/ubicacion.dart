import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/models/area.dart';
import 'package:camino_seguro/src/models/dependiente.dart';
import 'package:camino_seguro/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/services/dependientes.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/stores/registro_dependientes_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

  @override
  void initState() {
    super.initState();
    dependientesService = DependientesService.named('', context);
    _refresh();
  }

  Future<void> _refresh() async {
    await dependientesService.fetchData();
  }

  /// Si tu ThemeController devuelve Strings como '#FF0000', los convierte a Color.
  Color parseColor(dynamic colorValue) {
    if (colorValue is Color) return colorValue;
    if (colorValue is String) {
      var hex = colorValue.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex'; // agrega alpha si falta
      return Color(int.parse(hex, radix: 16));
    }
    // fallback
    return Colors.black;
  }

  /// Genera un color basado en el hash del texto (para las rutas).
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
          strokeWidth: 4.0,
        ));

        // Coloca un marcador en el último punto
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
                padding: const EdgeInsets.symmetric(),
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
      // polígonos
      for (final poly in area.geometria.coordinates) {
        final pts = poly.map((c) => LatLng(c[1], c[0])).toList();
        polygons.add(Polygon(
          points: pts,
          color: Colors.green.withAlpha(50),
          borderColor: Colors.green,
          borderStrokeWidth: 2,
          isFilled: true,
        ));
      }
      // líneas de área
      if (area.ruta.coordinates.isNotEmpty) {
        final pts =
            area.ruta.coordinates.map((c) => LatLng(c[1], c[0])).toList();
        polylines.add(Polyline(points: pts, color: Colors.red, strokeWidth: 3));
      }
    }

    return Expanded(
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(-16.5, -68.15),
              initialZoom: 14.0,
              interactionOptions:
                  InteractionOptions(flags: ~InteractiveFlag.doubleTapZoom),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
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
            child: FloatingActionButton(
              onPressed: _refresh,
              backgroundColor: Colors.white,
              child: const Icon(Icons.refresh, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final areasStore = context.watch<RegistroAreasStore>();

    return ScaffoldMessenger(
      key: ubicacionesMessenger,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: Scaffold(
          backgroundColor: parseColor(theme.background),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.map, size: 28, color: parseColor(theme.primary)),
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
                _mapaUbicacionesWidget(
                  areasStore.listaAreas,
                  RegistroDependientesStore.instance.listaDependientesRuta,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
