import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/constants/resources.dart';

class HeaderLoginAccount extends StatelessWidget {
  const HeaderLoginAccount(this.offline, {super.key});
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    return Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    Recursos.logoPrincipalFor(isDark: theme.isDark),
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        offline
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.signal_wifi_connected_no_internet_4_rounded,
                    color: theme.grey,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Estas sin conexión a internet',
                    style: TextStyle(fontWeight: FontWeight.w300),
                  ),
                ],
              )
            : const SizedBox(),
        offline
            ? Text(
                'Inicia sesión con los datos de la orden en curso',
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
              )
            : const SizedBox(),
      ],
    );
  }
}
