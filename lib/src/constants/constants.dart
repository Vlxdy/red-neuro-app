import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constantes {
  static final apiUrl = dotenv.get('URL_BASE');
  static final entorno = dotenv.get('ENVIRONMENT');
  static const secureHiveKey = 'llave_encriptacion_hive';
  static const timeout = 30;
  // static final imageCompressionQuality =
  // dotenv.get('IMAGE_COMPRESSION_QUALITY');
  static const gpsTimeout = 20;
  static const appId = 'bo.gob.agetic.lince2';
  // static final mapsApiUrl = dotenv.get('MAPS_API_URL');
  // static final mapsApiKey = dotenv.get('MAPS_API_KEY');
  static final sockets = dotenv.get('SOCKETS');
  static int get chatMaxFiles {
    final raw = dotenv.maybeGet('CHAT_MAX_FILES');
    return int.tryParse(raw ?? '') ?? 5;
  }

  static double get chatMaxFileMb {
    final raw = dotenv.maybeGet('CHAT_MAX_FILE_MB');
    return double.tryParse(raw ?? '') ?? 25;
  }

  static int get chatMaxFileBytes => (chatMaxFileMb * 1024 * 1024).round();

  static int get citasDuracionDefectoMinutos {
    final raw = dotenv.maybeGet('CITAS_DURACION_DEFECTO_MINUTOS');
    return int.tryParse(raw ?? '') ?? 60;
  }
}

class PatternRegexp {
  static String email =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!s#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  // static String number = r"^[0-9]*$";
  static String number = r'^\d+$';
}
