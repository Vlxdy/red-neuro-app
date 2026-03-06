import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/extensions/colores_extension.dart';

class CustomTextInputStyles {
  CustomTextInputStyles._();

  static InputDecoration decoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isDense = true,
    bool enabled = true,
    bool requiredData = false,
    Color? labelColor,
  }) {
    final theme = ThemeController.instance;

    OutlineInputBorder border(Color color, [double width = 1.2]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      isDense: isDense,
      filled: true,
      fillColor: enabled ? theme.bgCard2 : theme.monochromatic50,
      label: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: labelColor ?? theme.fontColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          children: [
            if (requiredData)
              TextSpan(
                text: ' *',
                style: TextStyle(color: theme.error, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      hintStyle: TextStyle(color: theme.grey, fontSize: 12),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: border(theme.monochromatic200),
      focusedBorder: border(theme.primary, 1.4),
      errorBorder: border(theme.error),
      focusedErrorBorder: border(theme.error, 1.4),
      disabledBorder: border(theme.monochromatic200),
    );
  }
}

class CustomTextInput extends StatefulWidget {
  final String title;
  final bool requiredData;
  final TextEditingController? controller;
  final Function(String value)? onChange;
  final VoidCallback? onTap;
  final Function(String? value, String alias)? validate;
  final RegExp? textFiltering;
  final bool obscure;
  final int? lines;
  final bool expandsWithContent;
  final bool disable;
  final bool disablePointer;
  final int? maxLength;
  final bool withBorder;
  final bool onlyNumbers;
  final String placeholder;
  final String? borderColor;
  final String? labelColor;
  final int? linesLabel;
  final AutovalidateMode autovalidateMode;

  const CustomTextInput({
    super.key,
    this.title = '',
    required this.controller,
    this.requiredData = false,
    this.obscure = false,
    this.validate,
    this.onTap,
    this.onChange,
    this.lines = 1,
    this.expandsWithContent = false,
    this.linesLabel = 1,
    this.placeholder = '',
    this.textFiltering,
    this.maxLength,
    this.disable = false,
    this.disablePointer = false,
    this.onlyNumbers = false,
    this.borderColor,
    this.labelColor,
    this.withBorder = true,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  State<CustomTextInput> createState() => _CustomTextInputState();
}

class _CustomTextInputState extends State<CustomTextInput> {
  bool _visibleText = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return TextFormField(
      focusNode: _focusNode,
      enabled: !(widget.disable || widget.disablePointer),
      minLines: widget.lines,
      maxLines: widget.expandsWithContent ? null : widget.lines,
      keyboardType: widget.onlyNumbers
          ? TextInputType.number
          : ((widget.expandsWithContent || (widget.lines ?? 1) > 1)
                ? TextInputType.multiline
                : TextInputType.text),
      inputFormatters: [
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
        if (widget.textFiltering != null)
          FilteringTextInputFormatter.allow(widget.textFiltering!),
        if (widget.onlyNumbers) FilteringTextInputFormatter.digitsOnly,
      ],
      obscureText: widget.obscure ? !_visibleText : false,
      autovalidateMode: widget.autovalidateMode,
      validator: (value) {
        if (widget.validate == null) return null;
        final result = widget.validate!(value, widget.title);
        return (result == null || result.isEmpty) ? null : result;
      },
      controller: widget.controller,
      onTap: widget.onTap,
      onChanged: (value) {
        if (widget.onChange != null) widget.onChange!(value);
      },
      cursorColor: widget.labelColor != null
          ? HexColor.fromHex(widget.labelColor)
          : theme.primary,
      style: TextStyle(
        color: widget.disable
            ? theme.grey
            : widget.labelColor != null
            ? HexColor.fromHex(widget.labelColor)
            : theme.fontColor,
      ),
      decoration: CustomTextInputStyles.decoration(
        label: widget.title,
        hint: widget.placeholder,
        enabled: !(widget.disable || widget.disablePointer),
        requiredData: widget.requiredData,
        labelColor: widget.labelColor != null
            ? HexColor.fromHex(widget.labelColor)
            : null,
        suffixIcon: widget.obscure
            ? IconButton(
                onPressed: () => setState(() => _visibleText = !_visibleText),
                icon: Icon(
                  _visibleText ? Icons.visibility_off : Icons.visibility,
                  color: widget.labelColor != null
                      ? HexColor.fromHex(widget.labelColor)
                      : theme.fontColor,
                ),
              )
            : null,
      ),
    );
  }
}
