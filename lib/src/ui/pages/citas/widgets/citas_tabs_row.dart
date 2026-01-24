import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class CitasTabsRow extends StatelessWidget {
  final TabController tabController;
  final VoidCallback onToggleFilters;
  final ThemeController theme;

  const CitasTabsRow({
    super.key,
    required this.tabController,
    required this.onToggleFilters,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            labelColor: theme.primary,
            indicatorColor: theme.primary,
            tabs: const [
              Tab(text: 'Agenda diaria'),
              Tab(text: 'Calendario'),
              Tab(text: 'Listado'),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onToggleFilters,
          icon: const Icon(PhosphorIconsRegular.funnel),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(8),
            minimumSize: const Size(40, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
