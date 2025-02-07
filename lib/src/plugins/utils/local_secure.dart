// import 'package:ciudadania_digital/common/utils.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class LocalSecure {
  /// Seguridad local
  static final LocalAuthentication auth = LocalAuthentication();

  // Variable para verificar si ya hay una autenticación en progreso
  static bool _authInProgress = false;

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics = [];
    try {
      availableBiometrics = await auth.getAvailableBiometrics();
      Logger.info("availableBiometrics 🛡: $availableBiometrics");
    } on PlatformException catch (e) {
      Logger.error(e.toString());
    }

    return availableBiometrics;
  }

  static Future<bool> checkBiometrics() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
      Logger.info("canCheckBiometrics 🛡: $canCheckBiometrics");
    } on PlatformException catch (e) {
      Logger.error(e.toString());
    }

    return canCheckBiometrics;
  }

  /// Verifica si el reconocimiento facial está disponible
  static Future<bool> isFaceRecognitionAvailable() async {
    try {
      // Obtiene la lista de biometrías disponibles en el dispositivo
      List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();
      // Verifica si el tipo de biometría "face" está presente
      if (availableBiometrics.contains(BiometricType.face)) {
        Logger.info('Reconocimiento facial disponible');
        return true;
      } else {
        Logger.info('Reconocimiento facial no disponible');
        return false;
      }
    } catch (e) {
      Logger.error('Error verificando reconocimiento facial: $e');
      return false;
    }
  }

  static Future<bool> autenticar(
      {String? titulo, String? message, bool biometricOnly = true}) async {
    if (_authInProgress) {
      Logger.error("Ya hay una autenticación en progreso");
      return false;
    }
    try {
      // Establece que la autenticación está en progreso
      _authInProgress = true;
      return await auth.authenticate(
          // localizedReason: 'Escanea tu huella dactilar para desbloquear',
          localizedReason:
              message ?? 'Escanea tu huella dactilar para continuar',
          options: AuthenticationOptions(
            biometricOnly: biometricOnly,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
          authMessages: <AuthMessages>[
            AndroidAuthMessages(
              signInTitle: titulo,
              cancelButton: 'Cancelar',
            ),
            const IOSAuthMessages(
              cancelButton: 'Cancelar',
            ),
          ]);
    } on PlatformException catch (e) {
      // Maneja el error de autenticación
      Logger.error('Error de autenticación: $e');
      return false;
    } finally {
      // Asegúrate de restablecer el estado de autenticación en progreso después de completar
      _authInProgress = false;
    }
  }

  static Future<bool> autenticarConReconocimientoFacial({
    String? titulo,
    String? message,
  }) async {
    try {
      // Verifica si el reconocimiento facial está disponible
      List<BiometricType> availableBiometrics = await getAvailableBiometrics();

      if (!availableBiometrics.contains(BiometricType.face)) {
        Logger.error('Reconocimiento facial no disponible');
        return false;
      }

      // Autenticar usando reconocimiento facial
      return await auth.authenticate(
        localizedReason:
            message ?? 'Usa el reconocimiento facial para continuar',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticación facial requerida',
            cancelButton: 'Cancelar',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
          ),
        ],
      );
    } on PlatformException catch (e) {
      Logger.error('Error al autenticar con reconocimiento facial: $e');
      return false;
    }
  }

  static void cancelAuthentication() {
    auth.stopAuthentication();
  }
}
