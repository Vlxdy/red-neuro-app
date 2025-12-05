import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String? title;
  final String? text;
  final IconData? icon;
  final Color? color;
  final String? textConfirm;
  final bool withCancel;
  final Function()? onConfirm;

  const ConfirmationDialog(
      {super.key,
      this.text,
      this.withCancel = true,
      this.icon,
      this.color,
      this.title,
      this.textConfirm,
      this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final size = MediaQuery.of(context).size;
    return Center(
      child: Container(
        width: size.width, // Makes it half the screen width
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
            color: theme.background, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text((title ?? ""),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFBEC3D2),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(icon ?? Icons.check_circle_outline_outlined,
                      size: 48, color: color ?? theme.secondary),
                  const SizedBox(height: 16),
                  Text(
                    text ?? '¿Está seguro de realizar esta acción?',
                    style: TextStyle(color: theme.grey, fontSize: 15),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
            Row(
              children: [
                Visibility(
                  visible: withCancel,
                  child: Flexible(
                    child: SimpleButton(
                      textColor: theme.black,
                      outlined: true,
                      title: 'Cancelar',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Visibility(
                    visible: withCancel, child: const SizedBox(width: 16)),
                Flexible(
                  child: SimpleButton(
                    title: textConfirm == null ? 'Confirmar' : textConfirm!,
                    background: theme.primary,
                    onTap: () {
                      Navigator.pop(context);
                      if (onConfirm != null) onConfirm!();
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
