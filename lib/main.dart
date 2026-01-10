import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:red_neuro_app/src/constants/keys.dart';
import 'dart:convert';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/plugins/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_neuro_app/src/config/init_app.dart';
import 'package:red_neuro_app/src/config/providers.dart';
import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> initHiveStorage() async {
  await Hive.initFlutter();
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool existsKey = await secureStorage.containsKey(
    key: Constantes.secureHiveKey,
  );
  if (!existsKey) {
    List<int> key = Hive.generateSecureKey();
    await secureStorage.write(
      key: Constantes.secureHiveKey,
      value: base64UrlEncode(key),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await initHiveStorage();

  await initializeDateFormatting('es', null);

  final AndroidDeviceInfo? deviceInfo = await Utils.getDeviceInfo();

  /// Para teléfonos Android con versión menor a Android 7.1
  if (deviceInfo != null && deviceInfo.version.sdkInt < 25) {
    ByteData data = await PlatformAssetBundle().load(
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
    TextTheme textTheme = ThemeData.light().textTheme;
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
            refreshListenable: appState,
          );

          return MaterialApp.router(
            // ✅ idioma por defecto español
            locale: const Locale('es'),

            // ✅ soporta solo español (puedes agregar más si deseas)
            supportedLocales: const <Locale>[
              Locale('es', ''), // Español
            ],

            // ✅ agrega las delegaciones necesarias
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            debugShowCheckedModeBanner: false,
            title: 'Red Neuro',
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            theme: ThemeData(
              useMaterial3: true,
              textTheme: textTheme,
              fontFamily: 'Poppins',
            ),
            routeInformationParser: router.routeInformationParser,
            routeInformationProvider: router.routeInformationProvider,
            routerDelegate: router.routerDelegate,
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
