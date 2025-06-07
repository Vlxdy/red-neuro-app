import 'package:camino_seguro/src/constants/constants.dart';
import 'package:camino_seguro/src/plugins/camera/camera_screen_store.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Geolocation {
  Geolocation._();
  static final instance = Geolocation._();

  final cameraStore = CameraScreenStore.instance;

  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return await Geolocator.openAppSettings();
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    cameraStore.cargando = true;
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        throw ErrorDescription('no tiene permisos');
      }
      LocationSettings settings = const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: Constantes.gpsTimeout),
      );
      final posicion =
          await Geolocator.getCurrentPosition(locationSettings: settings);
      if (posicion.latitude == 0 || posicion.longitude == 0) {
        throw ErrorDescription('Posición inválida');
      }
      cameraStore.posicion = posicion;
      return posicion;
    } catch (e) {
      Logger.error("Error al obtener la ubicación: $e");
      cameraStore.posicion = null;
      return null;
    } finally {
      Logger.info('[getCurrentLocation] finalizado obtencion de posicion');
      cameraStore.cargando = false;
    }
  }
}
