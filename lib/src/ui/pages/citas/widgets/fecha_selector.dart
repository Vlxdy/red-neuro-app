import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FechaSelector extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;

  const FechaSelector({
    super.key,
    required this.label,
    required this.value,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value != null ? formatter.format(value!) : label),
            ),
          ],
        ),
      ),
    );
  }
}
