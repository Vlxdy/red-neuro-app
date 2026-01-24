import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class CitasTabsRow extends StatelessWidget {
  final TabController tabController;
  final ThemeController theme;

  const CitasTabsRow({
    super.key,
    required this.tabController,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      labelColor: theme.primary,
      indicatorColor: theme.primary,
      tabs: const [
        Tab(text: 'Agenda diaria'),
        Tab(text: 'Calendario'),
        Tab(text: 'Listado'),
      ],
    );
  }
}
