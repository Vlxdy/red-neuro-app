import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvValidator {
  EnvValidator._();

  static const List<String> _requiredKeys = [
    'URL_BASE',
    'ENVIRONMENT',
    'SOCKETS',
  ];

  static void validate() {
    for (final key in _requiredKeys) {
      final value = dotenv.maybeGet(key);

      if (value == null || value.trim().isEmpty) {
        throw Exception('Falta la variable de entorno obligatoria: $key');
      }
    }
  }
}
