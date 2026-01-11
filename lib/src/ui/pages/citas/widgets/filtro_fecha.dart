import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FiltroFecha extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;

  const FiltroFecha({
    super.key,
    required this.label,
    required this.value,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event, size: 18),
          const SizedBox(width: 8),
          Text(value != null ? formatter.format(value!) : label),
        ],
      ),
    );
  }
}
