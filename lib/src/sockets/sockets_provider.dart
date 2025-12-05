// lib/src/providers/socket_provider.dart
import 'package:red_neuro_app/main.dart';
import 'package:red_neuro_app/src/config/socket_service.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:flutter/material.dart';

class SocketProvider extends ChangeNotifier {
  bool _connected = false;
  bool get connected => _connected;
  SocketProvider();

  /// Llamar tras el login, cuando tengas el userId
  Future<void> init(String userId, BuildContext context) async {
    SocketService.instance.connect(userId);
    // Cuando se conecte/desconecte
    SocketService.instance.on('connect', (_) {
      _connected = true;
      notifyListeners();
    });
    SocketService.instance.on('disconnect', (_) {
      _connected = false;
      notifyListeners();
    });

    // Cuando llegue nueva ubicación
    SocketService.instance.on<Map<String, dynamic>>(
      'ubicacion-actualizada',
      (data) async {
        final advertencia = data['advertencia'] as String?;
        Logger.info('Nueva ubicación recibida');

        showSnackBar(
          rootScaffoldMessengerKey,
          advertencia ?? 'Ubicación actualizada correctamente',
          state: advertencia != null
              ? StatusSnackBar.error
              : StatusSnackBar.success,
          colorText: Colors.white,
        );

        // Se elimina la actualización automática de dependientes ya que el
        // módulo de plan nutricional no utiliza esta información.
      },
    );
  }

  @override
  void dispose() {
    SocketService.instance.off('connect');
    SocketService.instance.off('disconnect');
    SocketService.instance.off('ubicacion-actualizada');
    SocketService.instance.disconnect();
    super.dispose();
  }
}
