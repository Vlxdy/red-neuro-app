import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';

class CitasAutocompleteSelectorField extends StatelessWidget {
  const CitasAutocompleteSelectorField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.onTap,
    super.key,
    this.errorText,
    this.onClear,
    this.enabled = true,
    this.requiredData = false,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String? errorText;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool enabled;
  final bool requiredData;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      decoration: CustomTextInputStyles.decoration(
        label: labelText,
        hint: hintText,
        enabled: enabled,
        requiredData: requiredData,
        suffixIcon: onClear != null
            ? IconButton(
                tooltip: 'Quitar',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              )
            : const Icon(Icons.expand_more),
      ).copyWith(errorText: errorText),
      onTap: enabled ? onTap : null,
    );
  }
}
