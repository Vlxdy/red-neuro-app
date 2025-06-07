import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constantes {
  static final apiUrl = dotenv.get('URL_BASE');
  static final entorno = dotenv.get('ENVIRONMENT');
  static const secureHiveKey = 'llave_encriptacion_hive';
  static const timeout = 30;
  static final imageCompressionQuality =
      dotenv.get('IMAGE_COMPRESSION_QUALITY');
  static const gpsTimeout = 20;
  static const appId = 'bo.gob.agetic.lince2';
  static final mapsApiUrl = dotenv.get('MAPS_API_URL');
  static final mapsApiKey = dotenv.get('MAPS_API_KEY');
}

class PatternRegexp {
  static String email =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!s#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  // static String number = r"^[0-9]*$";
  static String number = r'^\d+$';
}
