import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';

class FechaSelector extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;
  final IconData icon;
  final bool requiredData;

  const FechaSelector({
    super.key,
    required this.label,
    required this.value,
    required this.formatter,
    required this.onTap,
    this.icon = Icons.event,
    this.requiredData = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: value != null ? formatter.format(value!) : '',
    );
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: CustomTextInputStyles.decoration(
        label: label,
        requiredData: requiredData,
        suffixIcon: Icon(icon),
      ),
      onTap: onTap,
    );
  }
}
