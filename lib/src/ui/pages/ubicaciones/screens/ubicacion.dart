import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/models/area.dart';
import 'package:camino_seguro/src/models/dependiente.dart';
import 'package:camino_seguro/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/stores/registro_dependientes_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> areasMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Ubicaciones extends StatefulWidget {
  const Ubicaciones({super.key});

  @override
  State<Ubicaciones> createState() => UbicacionesScreen();
}

class UbicacionesScreen extends State<Ubicaciones> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _refresh() async {}

  Widget _mapaUbicacaionesWidget(
      List<Area> areas, List<DependienteRuta> rutasDeHoy) {
    List<Polygon> polygons = [];
    List<Polyline> polylines = [];
    final markers = <Marker>[];

    for (final dep in rutasDeHoy) {
      if (dep.rutadeHoy.coordinates.isNotEmpty) {
        final routePoints = dep.rutadeHoy.coordinates
            .map((coord) => LatLng(coord[1], coord[0]))
            .toList();
        polylines.add(
          Polyline(
            points: routePoints,
            color: Colors.purple,
            strokeWidth: 4.0,
          ),
        );
        final lastPoint = routePoints[routePoints.length - 1];
        markers.add(
          Marker(
            point: lastPoint,
            width: 100,
            height: 100,
            child: GestureDetector(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 24, color: Colors.purple),
                  const SizedBox(height: 4),
                  Container(
                    color: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      dep.codigo,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.purple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    for (final area in areas) {
      // Geometría (área)
      if (area.geometria.coordinates.isNotEmpty) {
        for (final polygonCoords in area.geometria.coordinates) {
          final polygonPoints =
              polygonCoords.map((coord) => LatLng(coord[1], coord[0])).toList();
          polygons.add(
            Polygon(
              points: polygonPoints,
              color: Colors.green.withAlpha(50),
              borderColor: Colors.green,
              borderStrokeWidth: 2,
              isFilled: true,
            ),
          );
        }
      }

      // Ruta (línea)
      if (area.ruta.coordinates.isNotEmpty) {
        final routePoints = area.ruta.coordinates
            .map((coord) => LatLng(coord[1], coord[0]))
            .toList();
        polylines.add(
          Polyline(
            points: routePoints,
            color: Colors.red,
            strokeWidth: 4.0,
          ),
        );
      }
    }

    return Expanded(
      child: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(-16.5, -68.15),
          initialZoom: 14.0,
          interactionOptions: InteractionOptions(
            flags: ~InteractiveFlag.doubleTapZoom,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          if (polygons.isNotEmpty)
            PolygonLayer(
              polygons: polygons,
            ),
          if (polylines.isNotEmpty)
            PolylineLayer(
              polylines: polylines,
            ),
          if (markers.isNotEmpty) MarkerLayer(markers: markers)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final areasStore = context.watch<RegistroAreasStore>();

    return ScaffoldMessenger(
      key: areasMessenger,
      child: RefreshIndicator(
          onRefresh: _refresh,
          child: Scaffold(
            backgroundColor: theme.background,
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map, size: 28, color: theme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Ubicaciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _mapaUbicacaionesWidget(
                      areasStore.listaAreas,
                      RegistroDependientesStore.instance
                          .listaDependientesRuta), // 👈 Aquí estaba el problema: faltaba el widget dentro del `Column`
                ],
              ),
            ),
          )),
    );
  }
}
