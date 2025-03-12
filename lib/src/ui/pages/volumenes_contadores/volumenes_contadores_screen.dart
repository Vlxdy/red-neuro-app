import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/meters_mangueras.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques.dart';

class VolumenesContadoresScreen extends StatefulWidget {
  const VolumenesContadoresScreen({super.key});

  @override
  State<VolumenesContadoresScreen> createState() =>
      _VolumenesContadoresScreenState();
}

class _VolumenesContadoresScreenState extends State<VolumenesContadoresScreen> {
  int? _selectedIndex;
  final List<Widget> _pages = [
    const VolumenesTanques(),
    const MetersManguerasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final List<_CardItem> items = [
      _CardItem(0,
          icon: SolarIconsOutline.gasStation,
          title: 'Volúmenes y tanques',
          color: theme.primary),
      _CardItem(1,
          icon: Icons.speed,
          title: 'Cantidad de mangueras',
          color: theme.secondary),
    ];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: _selectedIndex != null
          ? AppBar(
              backgroundColor: theme.background,
              title: const Text(
                'Volver',
                style: TextStyle(fontSize: 14),
              ),
              leading: _selectedIndex != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() {
                        _selectedIndex = null;
                      }),
                    )
                  : null,
            )
          : null,
      body: _selectedIndex == null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Icon(Icons.stacked_bar_chart,
                        color: theme.primary, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      'Volúmenes y contadores',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                ...items.map((
                  item,
                ) {
                  return SizedBox(
                    height: 200,
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedIndex = item.index;
                      }),
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Opacity(
                                  opacity: 0.1,
                                  child: Icon(
                                    item.icon,
                                    size: 150,
                                    color: item.color,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: item.color.withAlpha(35),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(item.icon,
                                          color: item.color, size: 28),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: item.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                })
              ]),
            )
          : _pages[_selectedIndex!],
    );
  }
}

class _CardItem {
  final IconData icon;
  final String title;
  final int index;
  final Color color;

  _CardItem(this.index,
      {required this.icon, required this.title, required this.color});
}
