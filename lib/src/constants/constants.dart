import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constantes {
  Constantes._();

  // =========================
  // Variables obligatorias
  // =========================
  static String get apiUrl => dotenv.get('URL_BASE');

  static String get entorno => dotenv.get('ENVIRONMENT');

  static String get sockets => dotenv.get('SOCKETS');

  // =========================
  // Variables opcionales
  // =========================
  static String get socketPath =>
      dotenv.maybeGet('SOCKET_PATH') ?? '/socket.io';

  static int get citasDuracionDefectoMinutos {
    final raw = dotenv.maybeGet('CITAS_DURACION_DEFECTO_MINUTOS');
    return int.tryParse(raw ?? '') ?? 60;
  }

  // =========================
  // Constantes internas
  // =========================
  static const String secureHiveKey = 'llave_encriptacion_hive';
  static const int timeout = 30;

  // =========================
  // Helpers de entorno
  // =========================
  static bool get isDev => entorno.toLowerCase() == 'dev';
  static bool get isProd => entorno.toLowerCase() == 'prod';
  static bool get isStaging => entorno.toLowerCase() == 'staging';
}

class PatternRegexp {
  static String email =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!s#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  // static String number = r"^[0-9]*$";
  static String number = r'^\d+$';
}
