import 'dart:io';

import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:http/http.dart' as http;

class Connection {
  static Future<bool> hasInternetConnected({bool upload = false}) async {
    final ping = await _hasInternetPing();
    final uploadPing = upload ? await _hasInternetUpload() : true;
    return ping && uploadPing;
  }

  static Future<bool> _hasInternetPing() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        Logger.info("Conectado correctamente");
        return true;
      }
      Logger.warning("Sin conexión a internet");
      return false;
    } catch (e) {
      Logger.warning("Sin conexión a internet");
      return false;
    }
  }

  static Future<double> _checkUploadLatency() async {
    final uri = Uri.parse('https://postman-echo.com/post');
    const dataSizeInKB = 90;
    final data = List<int>.generate(dataSizeInKB * 1024, (i) => i % 256);
    try {
      final stopwatch = Stopwatch()..start();

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/octet-stream'},
        body: data,
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
        final dataSizeInBits = data.length * 8; // Convert bytes to bits
        final uploadSpeedMbps = (dataSizeInBits / elapsedSeconds) / 1e6;
        Logger.info(
          'Elapsed time: ${elapsedSeconds.toStringAsFixed(2)} seconds',
        );
        return uploadSpeedMbps;
      } else {
        Logger.warning('Upload failed with status: ${response.statusCode}');
        return 0;
      }
    } catch (e, stacktrace) {
      Logger.error("Error en latencia de subida $e");
      Logger.error(stacktrace.toString());
      return 0;
    }
  }

  static Future<bool> _hasInternetUpload() async {
    final latency = await _checkUploadLatency();
    Logger.info('Latencia de internet (upload) -> $latency Mbps');
    if (latency < 1) {
      Logger.warning("Latencia de subida lenta");
      return false;
    }
    return true;
  }
}
