import 'package:flutter/material.dart';

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
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String? errorText;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
        errorText: errorText,
        suffixIcon: onClear != null
            ? IconButton(
                tooltip: 'Quitar',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              )
            : const Icon(Icons.expand_more),
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
