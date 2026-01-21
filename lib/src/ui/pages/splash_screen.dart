import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/init_app.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/resources.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Widget _logo(bool isDark) {
    return Column(
      children: <Widget>[
        Container(
          height: 100,
          width: 200,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.contain,
              image: AssetImage(Recursos.logoPrincipalFor(isDark: isDark)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() async {
    await InitAppController.instance.initApp();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    // notifications.initNotifications();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background,
      body: Container(
        decoration: const BoxDecoration(),
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _logo(theme.isDark),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: theme.primary),
          ],
        ),
      ),
    );
  }
}
