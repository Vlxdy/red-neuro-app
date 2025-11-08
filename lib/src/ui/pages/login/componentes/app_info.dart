import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:flutter/material.dart';

class AppInfo extends StatelessWidget {
  const AppInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final info = Auth.instance.appInfo;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 20,
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 70),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 10,
              ),
              Text(
                'Versión ${info.version}',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: theme.primary),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
