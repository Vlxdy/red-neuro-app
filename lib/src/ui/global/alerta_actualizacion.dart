import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/constants/keys.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:flutter/material.dart';

class DialogService {
  static Future<void> showAlertDialog(
    String title,
    String message,
    String link,
  ) async {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return Dialog(
          child: ConfirmationDialog(
            withCancel: false,
            title:
                'Existe una nueva versión de la aplicación, es recomendable que descargue la última versión',
            text:
                'Por favor comuniquese con el personal de soporte para obtener una nueva versión',
            textConfirm: 'Aceptar',
            onConfirm: () async {
              final PreferencesService preference = PreferencesService.instance;
              await preference.setBool(Keys.mostrarDialogo, false);
              // await Utils.abrirURL(link);
            },
          ),
        );
      },
    );
  }
}
