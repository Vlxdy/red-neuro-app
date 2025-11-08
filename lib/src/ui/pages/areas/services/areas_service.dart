import 'package:alimenta_app/src/config/service_config.dart';
import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/constants/constants.dart';
import 'package:alimenta_app/src/constants/network.dart';
import 'package:alimenta_app/src/models/area.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:alimenta_app/src/ui/common/snackbar/snackbar.dart';
import 'package:alimenta_app/src/ui/global/loading_animation.dart';
import 'package:alimenta_app/src/ui/pages/areas/screens/areas.dart';
import 'package:alimenta_app/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';

class AreasService extends ServiceConfig {
  AreasService(super.urlBase, super.context);
  final theme = ThemeController.instance;
  late String idUsuario = '';
  final store = RegistroAreasStore.instance;

  AreasService.named(super.urlBase, super.context) {
    _initializeIdUsuario();
  }

  void _initializeIdUsuario() async {
    idUsuario = (await Auth.instance.idUsuario) ?? '';
  }

  Future<void> fetchData() async {
    await getAreas();
  }

  Future<void> getAreas() async {
    try {
      final response = await fetch('/areas',
          type: HttpProtocol.get, params: {'limite': '50'});
      Logger.success('response -> ${response.data}');
      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription('La petición no se pudo completar');
      }
      if (response.status == StatusNetwork.connected) {
        store.setlistaAreas = (response.data['filas'] as List)
            .map((e) => Area.fromJson(e))
            .toList();
      }
      Logger.error('Registros obtenidos correctamente');
    } catch (e) {
      Logger.error('Exception al obtener listado del areas $e');
    } finally {}
  }

  Future<void> registrarArea(
    BuildContext context,
    String nombre,
    List<Map<String, double>> ruta,
    List<Map<String, double>> geometria,
    String? idEdit,
  ) async {
    try {
      if (context.mounted) {
        LoadingAnimation.instance.state = Overlay.of(context);
        LoadingAnimation.instance.showLoading(mensaje: 'Registrando área...');
      }

      final body = {
        'nombre': nombre,
        'ruta': ruta,
        'geometria': geometria,
      };
      final path = idEdit != null ? '/areas/$idEdit' : '/areas';
      final response = await fetch(path,
          type: idEdit != null ? HttpProtocol.patch : HttpProtocol.post,
          body: body,
          withAuthorization: true);

      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription(response.message);
      }
      showSnackBar(
        areasMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (e, stacktrace) {
      Logger.error('Error al registrar área: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        areasMessenger,
        'Ocurrió un error al registrar el área',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> cambiarEstadoArea(
    BuildContext context,
    Area area,
  ) async {
    try {
      if (context.mounted) {
        LoadingAnimation.instance.state = Overlay.of(context);
        LoadingAnimation.instance
            .showLoading(mensaje: 'Cambiar estado área...');
      }
      final path =
          '/areas/${area.id}${area.estado == 'ACTIVO' ? '/inactivacion' : '/activacion'}';
      final response = await fetch(path,
          type: HttpProtocol.patch, withAuthorization: true, body: {});

      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription(response.message);
      }
      showSnackBar(
        areasMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (e, stacktrace) {
      Logger.error('Error al actualizar estado de área: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        areasMessenger,
        'Ocurrió un error al actualizar estaso del área',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<List<LatLng>> calcularRuta(List<LatLng> puntos) async {
    try {
      final formattedCoordinates =
          puntos.map((p) => [p.longitude, p.latitude]).toList();

      final url = Uri.parse(Constantes.mapsApiUrl);
      final response = await http.post(
        url,
        headers: {
          'Authorization': Constantes.mapsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'coordinates': formattedCoordinates,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al obtener la ruta: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final geometry = data['routes'][0]['geometry'] as String;

      final polylinePoints = PolylinePoints();
      final decoded = polylinePoints.decodePolyline(geometry);

      final result = decoded
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      return result;
    } catch (e) {
      Logger.info('Error en calcularRutaDesdeBackend: $e');
      return [];
    }
  }
}
