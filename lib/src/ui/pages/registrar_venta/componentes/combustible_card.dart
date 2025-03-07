import 'dart:ui';
import 'package:flutter/material.dart';

class CombustibleCard extends StatelessWidget {
  final String title;
  final int ventasRegistradas;
  final Color color;
  final VoidCallback onPressedNuevaVenta;

  const CombustibleCard({
    super.key,
    required this.title,
    required this.ventasRegistradas,
    required this.color,
    required this.onPressedNuevaVenta,
  });

  @override
  Widget build(BuildContext context) {
    ;
    return SizedBox(
      height: 200,
      child: InkWell(
        onTap: onPressedNuevaVenta,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.add_circle,
                    size: 150,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.local_gas_station, color: color, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title.toUpperCase(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      ventasRegistradas.toString(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
