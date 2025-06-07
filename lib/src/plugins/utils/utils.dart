import 'dart:io';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/extensions/strings_extensions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';

final List<dynamic> coloresTipo = [
  {
    "tipo": "Gas Natural Vehicular",
    "color": const Color(0xFF006400),
  },
  {
    "tipo": "Diesel Oil",
    "color": const Color(0xFF0000FF),
  },
  {
    "tipo": "Gasolina Especial",
    "color": const Color(0xFF008000),
  },
  {
    "tipo": "Gasolina Premium",
    "color": const Color(0xFFFF8C00),
  },
  {
    "tipo": "Gasolina Ron",
    "color": const Color(0xFFB22222),
  },
  {
    "tipo": "Super Etanol 92",
    "color": const Color(0xFF008000),
  },
  {
    "tipo": "Gasolina Ultra Premium 100",
    "color": const Color(0xFF800080),
  },
  // "Gas Natural": const Color(0xFF008000),
  // "Gasolina especial": Colors.redAccent,
  // "Gasolina Premium": Colors.yellow,
  // "GE+": Colors.deepOrangeAccent,
  // "Diesel Oil": Colors.lime,
];

class Utils {
  static Future<void> deleteFiles(List<String> paths) async {
    if (paths.isNotEmpty) {
      for (var path in paths) {
        var file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  static String formatearFecha(String? fecha) {
    if (fecha == null) return '';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha));
    } catch (e) {
      return fecha.contains('T')
          ? fecha.split('T')[0].replaceAll('-', '/')
          : '';
    }
  }

  /// Método que obtiene la versión de la aplicación
  static Future<String> versionAplicacion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static Future<AndroidDeviceInfo?> getDeviceInfo() async {
    if (!Platform.isAndroid) return null;
    final devicePlugin = DeviceInfoPlugin();
    return await devicePlugin.androidInfo;
  }

  static armarNombre(Map<String, dynamic> data,
      {bool noSegundoApellido = true, bool iniciales = false}) {
    final nombres = data['nombres'].isNotEmpty
        ? iniciales
            ? data['nombres'][0]
            : data['nombres']
        : '';
    final primerApellido = data['primerApellido'].isNotEmpty
        ? iniciales
            ? data['primerApellido'][0]
            : data['primerApellido']
        : '';
    final segundoApellido = data['segundoApellido'].isNotEmpty
        ? iniciales
            ? data['segundoApellido'][0]
            : data['segundoApellido']
        : '';
    final strNombre = iniciales
        ? '$nombres$primerApellido'
        : '${(nombres as String).capitalize()} ${(primerApellido as String).capitalize()}';
    return noSegundoApellido ? strNombre : '$strNombre $segundoApellido';
  }

  static Color getFuelColor(String fuel) {
    return coloresTipo.firstWhere((el) => el['tipo'] == fuel)['color'] ??
        ThemeController.instance.primary;
  }
}
