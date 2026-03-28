import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:red_neuro_app/firebase_options.dart';
import 'package:red_neuro_app/src/config/app_theme.dart';
import 'package:red_neuro_app/src/config/env_validator.dart';
import 'package:red_neuro_app/src/config/init_app.dart';
import 'package:red_neuro_app/src/config/providers.dart';
import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/keys.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/plugins/utils/utils.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> initHiveStorage() async {
  await Hive.initFlutter();

  const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  final bool existsKey = await secureStorage.containsKey(
    key: Constantes.secureHiveKey,
  );

  if (!existsKey) {
    final List<int> key = Hive.generateSecureKey();

    await secureStorage.write(
      key: Constantes.secureHiveKey,
      value: base64UrlEncode(key),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  await dotenv.load(fileName: '.env.$flavor');
  EnvValidator.validate();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  await initHiveStorage();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('es', null);

  final AndroidDeviceInfo? deviceInfo = await Utils.getDeviceInfo();

  /// Para teléfonos Android con versión menor a Android 7.1
  if (deviceInfo != null && deviceInfo.version.sdkInt < 25) {
    final ByteData data = await PlatformAssetBundle().load(
      'assets/raw/lets-encrypt-r3.pem',
    );

    SecurityContext.defaultContext.setTrustedCertificatesBytes(
      data.buffer.asUint8List(),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  void setLocale(Locale value) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    inicializar();
  }

  Future<void> inicializar() async {
    final PreferencesService preferences = PreferencesService.instance;
    await preferences.setBool(Keys.mostrarDialogo, true);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: proveedores(context),
      child: FutureBuilder(
        future: InitAppController.instance.initTheme(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          final AuthStore appState = AuthStore.instance;

          final GoRouter router = GoRouter(
            navigatorKey: navigatorKey,
            observers: <NavigatorObserver>[MyRouteObserver.instance],
            initialLocation: '/${RouteNames.splashScreen}',
            routes: routes,
            redirect: redirectRoutes,
            refreshListenable: Listenable.merge(<Listenable>[
              appState,
              ThemeController.instance,
            ]),
          );

          return ValueListenableBuilder<bool>(
            valueListenable: ThemeController.instance.brightness,
            builder: (BuildContext context, bool isLight, Widget? child) {
              return MaterialApp.router(
                locale: const Locale('es'),
                supportedLocales: const <Locale>[Locale('es', '')],
                localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                debugShowCheckedModeBanner: false,
                title: 'Red Neuro',
                scaffoldMessengerKey: rootScaffoldMessengerKey,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
                routeInformationParser: router.routeInformationParser,
                routeInformationProvider: router.routeInformationProvider,
                routerDelegate: router.routerDelegate,
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
