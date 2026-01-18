import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class SimpleButton extends StatelessWidget {
  final Color? background;
  final bool? fullWidth;
  final double? width;
  final bool elevated;
  final Color? textColor;
  final IconData? suffixicon;
  final IconData? preffixicon;
  final Widget? customPreffixicon;
  final bool outlined;
  final Function()? onTap;
  final String title;
  final bool? disabled;
  final double? height;

  SimpleButton({
    super.key,
    this.background,
    this.textColor,
    this.onTap,
    this.fullWidth = true,
    this.elevated = true,
    this.title = "",
    this.suffixicon,
    this.preffixicon,
    this.customPreffixicon,
    this.width,
    this.outlined = false,
    this.disabled = false,
    this.height,
  });

  final theme = ThemeController.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: disabled!
              ? theme.grey.withValues(alpha: .3)
              : background ?? theme.primary,
        ),
        boxShadow: [
          BoxShadow(
            color: _boxShadowColor,
            offset: const Offset(0, 0),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
        color: disabled!
            ? theme.grey.withValues(alpha: .3)
            : outlined
            ? theme.transparent
            : background ?? theme.primary,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Material(
        color: theme.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: disabled! ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: fullWidth != null && fullWidth!
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                customPreffixicon ?? _preffixicon,
                SizedBox(width: preffixicon != null ? 8 : 0),
                Center(
                  child: AutoSizeText(
                    title,
                    maxLines: 2,
                    maxFontSize: 16,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: disabled!
                          ? theme.grey
                          : outlined
                          ? background
                          : textColor ?? theme.white,
                    ),
                  ),
                ),
                SizedBox(width: suffixicon != null ? 8 : 0),
                _suffixicon,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget get _preffixicon {
    return preffixicon != null
        ? Icon(
            preffixicon,
            color: disabled!
                ? theme.grey
                : outlined
                ? background
                : textColor ?? theme.white,
          )
        : const SizedBox();
  }

  Widget get _suffixicon {
    return suffixicon != null
        ? Icon(
            suffixicon,
            color: disabled!
                ? theme.grey
                : outlined
                ? background
                : textColor ?? theme.white,
          )
        : const SizedBox();
  }

  Color get _boxShadowColor {
    return elevated ? theme.grey.withValues(alpha: 0.1) : theme.transparent;
  }
}
