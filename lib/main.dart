import 'dart:io';
import 'package:camino_seguro/src/constants/keys.dart';
import 'dart:convert';
import 'package:camino_seguro/src/constants/constants.dart';
import 'package:camino_seguro/src/plugins/utils/preferences.dart';
import 'package:camino_seguro/src/plugins/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camino_seguro/src/config/init_app.dart';
import 'package:camino_seguro/src/config/providers.dart';
import 'package:camino_seguro/src/config/routes.dart';
import 'package:camino_seguro/src/plugins/auth/auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> initHiveStorage() async {
  await Hive.initFlutter();
  const secureStorage = FlutterSecureStorage();
  var existsKey =
      await secureStorage.containsKey(key: Constantes.secureHiveKey);
  if (!existsKey) {
    var key = Hive.generateSecureKey();
    await secureStorage.write(
        key: Constantes.secureHiveKey, value: base64UrlEncode(key));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initHiveStorage();
  final deviceInfo = await Utils.getDeviceInfo();

  /// Para teléfonos Android con versión menor a Android 7.1
  if (deviceInfo != null && deviceInfo.version.sdkInt < 25) {
    ByteData data =
        await PlatformAssetBundle().load('assets/raw/lets-encrypt-r3.pem');
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(data.buffer.asUint8List());
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;
  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  void initState() {
    super.initState();
    inicializar();
  }

  inicializar() async {
    final preferences = PreferencesService.instance;
    await preferences.setBool(Keys.mostrarDialogo, true);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = ThemeData.light().textTheme;
    return MultiProvider(
      providers: proveedores(context),
      child: FutureBuilder(
          future: InitAppController.instance.initTheme(),
          builder: (context, snapshot) {
            final appState = AuthStore.instance;
            final router = GoRouter(
              navigatorKey: navigatorKey,
              observers: [MyRouteObserver.instance],
              initialLocation: '/${RouteNames.splashScreen}',
              routes: routes,
              redirect: redirectRoutes,
              refreshListenable: appState,
            );

            return MaterialApp.router(
              locale: _locale,
              debugShowCheckedModeBanner: false,
              title: 'Camino seguro',
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              theme: ThemeData(
                  useMaterial3: true,
                  textTheme: textTheme,
                  fontFamily: 'Poppins'),
              routeInformationParser: router.routeInformationParser,
              routeInformationProvider: router.routeInformationProvider,
              routerDelegate: router.routerDelegate,
            );
          }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
