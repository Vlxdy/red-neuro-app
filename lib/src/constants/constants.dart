import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constantes {
  static final apiUrl = dotenv.get('URL_BASE');
  static final entorno = dotenv.get('ENVIRONMENT');
  static const secureHiveKey = 'llave_encriptacion_hive';
  static final oidcIssuer = dotenv.get('OIDC_ISSUER');
  static final oidcClientId = dotenv.get('OIDC_CLIENT_ID');
  static final oidcRedirectUri = dotenv.get('OIDC_REDIRECT_URI');
  static const timeout = 30;
}

enum TipoAsociacion { propietario, poseedor, conductor }
extension ExtTipoAsociacion on TipoAsociacion {
  String get name {
    switch (this) {
      case TipoAsociacion.propietario:
        return 'PROPIETARIO';
      case TipoAsociacion.poseedor:
        return 'POSEEDOR';
      case TipoAsociacion.conductor:
        return 'CONDUCTOR';
    }
  }
}

class PatternRegexp {
  static String email =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!s#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  // static String number = r"^[0-9]*$";
  static String number = r'^\d+$';
}
