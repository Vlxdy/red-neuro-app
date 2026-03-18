import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:flutter/material.dart';

class PerfilInfoCard extends StatelessWidget {
  final Color bgColor;
  final Color borderColor;
  final IconData headerIcon;
  final String headerTitle;
  final List<Map<String, dynamic>> items;
  final void Function(String field, String value)? onCopy;
  const PerfilInfoCard({
    super.key,
    required this.bgColor,
    required this.borderColor,
    required this.headerIcon,
    required this.headerTitle,
    required this.items,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: borderColor),
      ),
      color: bgColor,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(headerIcon, color: theme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  headerTitle,
                  style: TextStyle(
                    color: theme.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 18),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < items.length; i++) ...<Widget>[
                  _InfoItem(
                    item: items[i],
                    onCopy: onCopy,
                  ),
                  if (i != items.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: theme.grey.withValues(alpha: 0.16),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.item, required this.onCopy});

  final Map<String, dynamic> item;
  final void Function(String field, String value)? onCopy;

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    final String label = (item['clave'] ?? '').toString();
    final String value = (item['valor'] ?? '').toString().trim();
    final bool copyable = item['copiable'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: theme.fontColor.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!copyable || value.isEmpty || onCopy == null) return;
            onCopy!(label, value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: theme.fontColor,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (copyable) ...<Widget>[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: theme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
