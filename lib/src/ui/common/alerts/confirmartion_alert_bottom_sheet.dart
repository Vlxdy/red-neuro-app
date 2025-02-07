import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:flutter/material.dart';

class ConfirmationAlertBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final String? confirmTitle;
  final Function()? onConfirm;
  const ConfirmationAlertBottomSheet(
      {required this.title,
      this.subtitle,
      super.key,
      this.confirmTitle,
      this.onConfirm,
      this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text((title),
              style: TextStyle(
                  color: theme.fontColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                icon ??
                    Icon(Icons.check_circle_rounded,
                        size: 56, color: theme.success),
                const SizedBox(height: 16),
                Text(
                  subtitle ?? '¿Está seguro de realizar esta acción?',
                  style: TextStyle(color: theme.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
          Row(
            children: [
              Flexible(
                child: SimpleButton(
                  title: 'Cancelar',
                  outlined: true,
                  background: theme.error,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: SimpleButton(
                  title: confirmTitle ?? 'Aceptar',
                  onTap: () {
                    Navigator.of(context).pop(true);
                    if (onConfirm != null) onConfirm!();
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
