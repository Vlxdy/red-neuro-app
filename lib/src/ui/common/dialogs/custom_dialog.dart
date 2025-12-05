import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:flutter/material.dart';

class CutomDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? confirmTitle;
  final Function()? onConfirm;
  final String? textConfirm;
  final Widget content;
  final bool withCancel;
  const CutomDialog(
      {super.key,
      this.confirmTitle,
      this.onConfirm,
      required this.title,
      this.subtitle,
      required this.content,
      this.withCancel = true,
      this.textConfirm});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
          color: theme.background, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text((title),
              textAlign: TextAlign.center,
              style: TextStyle(
                  // color: Color(0xFFBEC3D2),
                  color: theme.fontColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text((subtitle ?? ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                  // color: Color(0xFFBEC3D2),
                  color: theme.fontColor,
                  fontSize: 12,
                  fontWeight: FontWeight.normal)),
          const SizedBox(
            height: 15,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              Visibility(
                visible: withCancel,
                child: Flexible(
                  child: SimpleButton(
                    title: 'Cancelar',
                    outlined: true,
                    // background: Colors.transparent,
                    // textColor: theme.error,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
              ),
              Visibility(visible: withCancel, child: const SizedBox(width: 16)),
              Flexible(
                child: SimpleButton(
                  title: textConfirm == null ? 'Confirmar' : textConfirm!,
                  background: theme.primary,
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
