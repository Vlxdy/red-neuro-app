import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:flutter/material.dart';

class PerfilInfoCard extends StatelessWidget {
  final Color bgColor;
  final Color borderColor;
  final IconData headerIcon;
  final String headerTitle;
  final List<Map<String, dynamic>> items;
  const PerfilInfoCard({
    super.key,
    required this.bgColor,
    required this.borderColor,
    required this.headerIcon,
    required this.headerTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: borderColor),
      ),
      color: bgColor,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  style: BorderStyle.solid,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(headerIcon, color: theme.primary),
                const SizedBox(width: 5),
                Text(
                  headerTitle,
                  style: TextStyle(
                    color: theme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 22),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < items.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          items[i]['clave'],
                          style: TextStyle(color: theme.grey),
                        ),
                        Text(items[i]['valor']),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
