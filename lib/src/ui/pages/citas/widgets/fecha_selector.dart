import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FechaSelector extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;
  final IconData icon;

  const FechaSelector({
    super.key,
    required this.label,
    required this.value,
    required this.formatter,
    required this.onTap,
    this.icon = Icons.event,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: value != null ? formatter.format(value!) : '',
    );
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 18,
        ),
      ),
      onTap: onTap,
    );
  }
}
