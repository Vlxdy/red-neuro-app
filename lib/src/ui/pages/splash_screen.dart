import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/init_app.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/resources.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Notifications notifications = Notifications();

  Widget _logo() {
    return Column(children: [
      Container(
        height: 100,
        width: 200,
        decoration: const BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.contain,
                image: AssetImage(Recursos.logoPrincipal))),
      ),
    ]);
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
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background,
      body: Container(
        decoration: const BoxDecoration(),
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _logo(),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: theme.primary),
          ],
        ),
      ),
    );
  }
}
