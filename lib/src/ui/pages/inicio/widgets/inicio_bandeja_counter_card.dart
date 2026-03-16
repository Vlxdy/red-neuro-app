import 'package:flutter/material.dart';

class InicioBandejaCounterCard extends StatelessWidget {
  const InicioBandejaCounterCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.onTap,
    required this.accentColor,
  });

  final String titulo;
  final int valor;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.16),
              accentColor.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: accentColor.withValues(alpha: 0.24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: accentColor),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            Text(
              '$valor',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
