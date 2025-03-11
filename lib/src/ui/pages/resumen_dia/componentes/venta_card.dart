import 'package:control_ventas_movil/src/models/resumen_dia.dart';
import 'package:control_ventas_movil/src/ui/common/avatardata/avatar_data.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';

class VentaCard extends StatelessWidget {
  final ThemeController theme;
  final IconData iconData;
  final String titulo;
  final String total;
  final List<DetalleVenta> combustibles;

  const VentaCard({
    super.key,
    required this.theme,
    required this.iconData,
    required this.titulo,
    required this.total,
    required this.combustibles,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.primary20,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: theme.secondary,
              radius: 20,
              child: Icon(iconData, color: theme.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.secondary,
                ),
              ),
            ),
            combustibles != []
                ? InkWell(
                    onTap: () => _showFuelDetails(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: AvatarData(
                        avatars: combustibles
                            .take(2)
                            .map((c) => AvatarType(
                                  text: c.codigo,
                                  background: c.color != null
                                      ? Color(int.parse(
                                          '0xFF${c.color!.substring(1)}'))
                                      : theme.primary,
                                ))
                            .toList(),
                        size: 32,
                        remainingCount: combustibles.length > 2
                            ? combustibles.length - 2
                            : null,
                        spacing: -10,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            const SizedBox(width: 12),
            Text(
              total,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Detalles de Combustibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.secondary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: combustibles.length,
                  itemBuilder: (context, index) {
                    final combustible = combustibles[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (combustible.color != null)
                            ? Color(int.parse('0xFF${combustible.color!.substring(1)}'))
                            : theme.primary,
                        child: Icon(Icons.local_gas_station, color: theme.white),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            combustible.codigo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.black,
                            ),
                          ),
                          Text(
                            combustible.nombre ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.black,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        combustible.cantidad,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
