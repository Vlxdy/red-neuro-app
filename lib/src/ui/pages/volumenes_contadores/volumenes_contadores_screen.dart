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
      _CardItem(
        icon: SolarIconsOutline.gasStation,
        title: 'Volúmenes Tanques',
        index: 0,
      ),
      _CardItem(
        icon: SolarIconsOutline.bus,
        title: 'Cantidad Mangueras',
        index: 1,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Volúmenes y Contadores'),
        leading: _selectedIndex != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedIndex = null;
                }),
              )
            : null,
      ),
      body: _selectedIndex == null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: items.map((item) {
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
                                    Icons.add_circle,
                                    size: 150,
                                    color: theme.primary,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.primary,
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
                                      Icon(Icons.local_gas_station,
                                          color: theme.primary, size: 28),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: theme.black,
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
                }).toList(),
              ),
            )
          : _pages[_selectedIndex!],
    );
  }
}

class _CardItem {
  final IconData icon;
  final String title;
  final int index;

  _CardItem({required this.icon, required this.title, required this.index});
}
