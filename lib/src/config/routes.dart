import 'dart:async';

import 'package:control_ventas_movil/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/registrar_venta.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia.dart';
import 'package:control_ventas_movil/src/ui/pages/seguridad/configuracion_desbloqueo.dart';
import 'package:control_ventas_movil/src/ui/pages/seguridad/configuracion_pin_seguridad.dart';
import 'package:control_ventas_movil/src/ui/pages/home/home.dart';
import 'package:control_ventas_movil/src/ui/pages/informacion_personal/informacion_personal.dart';
import 'package:control_ventas_movil/src/ui/pages/mi_cuenta/mi_cuenta.dart';
import 'package:control_ventas_movil/src/ui/pages/perfil/perfil.dart';
import 'package:control_ventas_movil/src/ui/pages/procesar_sesion.dart';
import 'package:control_ventas_movil/src/ui/pages/recuperar_contrasena/recuperar_contrasena.dart';
import 'package:control_ventas_movil/src/ui/pages/seguridad/modificar_pin_seguridad.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/pages/login/login.dart';
import 'package:control_ventas_movil/src/ui/pages/login/componentes/login_account_page.dart';
import 'package:control_ventas_movil/src/ui/pages/splash_screen.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//Lista de rutas
//Nombres
class RouteNames {
  static const homeScaffolding = 'home_scaffolding';
  static const splashScreen = 'splash_screen';
  static const login = 'login';
  static const olvideContrasena = 'olvide_contrasena';
  static const loginAccount = 'login_account';
  static const informacionPersonal = 'informacion_personal';
  static const cambiarContrasena = 'cambiar_contrasena';
  static const configuraciones = 'configuraciones';
  static const perfil = 'perfil';
  static const home = 'home';
  static const procesarSesion = 'procesar_sesion';
  static const configurarPinSeguridad = 'configurar_pin_seguridad';
  static const configurarDesbloqueo = 'configurar_desbloqueo';
  static const modificarPin = 'modificar_pin';
  static const controlScreen = 'control_screen';
  static const resumenDia = 'resumen_dia';
  static const registrarVenta = 'registrar_venta';
  // adicionar nuevas rutas

  static const routesConfiguration = [
    '/$login',
    '/$loginAccount',
    '/$olvideContrasena',
    '/$controlScreen',
    '/$resumenDia',
  ];
}

//Configuración
List<RouteBase> routes = [
  GoRoute(
    name: RouteNames.splashScreen,
    path: '/${RouteNames.splashScreen}',
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
      name: RouteNames.login,
      path: '/${RouteNames.login}',
      builder: (context, state) => const Login()),
  GoRoute(
      name: RouteNames.loginAccount,
      path: '/${RouteNames.loginAccount}',
      builder: (context, state) => const LoginAccount()),
  GoRoute(
      name: RouteNames.olvideContrasena,
      path: '/${RouteNames.olvideContrasena}',
      builder: (context, state) => const OlvideContrasena()),
  GoRoute(
      name: RouteNames.informacionPersonal,
      path: '/${RouteNames.informacionPersonal}',
      builder: (context, state) => const InformacionPersonal()),
  GoRoute(
      name: RouteNames.cambiarContrasena,
      path: '/${RouteNames.cambiarContrasena}',
      builder: (context, state) => const CambiarContrasena()),
  GoRoute(
      name: RouteNames.configuraciones,
      path: '/${RouteNames.configuraciones}',
      builder: (context, state) => const Micuenta()),

  /// New routes
  GoRoute(
      name: RouteNames.perfil,
      path: '/${RouteNames.perfil}',
      builder: (context, state) => const Perfil()),
  GoRoute(
      name: RouteNames.home,
      path: '/${RouteNames.home}',
      builder: (context, state) => const HomePage()),
  GoRoute(
    name: RouteNames.procesarSesion,
    path: '/${RouteNames.procesarSesion}',
    builder: (context, state) => const ProcesarSesion(),
  ),
  GoRoute(
    name: RouteNames.configurarPinSeguridad,
    path: '/${RouteNames.configurarPinSeguridad}',
    builder: (context, state) => const ConfiguracionPinSeguridad(),
  ),
  GoRoute(
    name: RouteNames.configurarDesbloqueo,
    path: '/${RouteNames.configurarDesbloqueo}',
    builder: (context, state) => const ConfiguracionDesbloqueo(),
  ),
  GoRoute(
    name: RouteNames.modificarPin,
    path: '/${RouteNames.modificarPin}',
    builder: (context, state) => const ModificarPinSeguridad(),
  ),
  GoRoute(
    name: RouteNames.controlScreen,
    path: '/${RouteNames.controlScreen}',
    builder: (context, state) => const Control(),
  ),
  GoRoute(
    name: RouteNames.resumenDia,
    path: '/${RouteNames.resumenDia}',
    builder: (context, state) => const ResumenDelDiaPage(),
  ),
  GoRoute(
    name: RouteNames.registrarVenta,
    path: '/${RouteNames.registrarVenta}',
    builder: (context, state) => const RegistrarVentaPage(),
  )
];

// --------------------------------------------------------------
// -------------------- MODIFICAR CON CUIDADO -------------------
// --------------------------------------------------------------

//Observer
class MyRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  MyRouteObserver._();
  static final instance = MyRouteObserver._();

  final Set history = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    history.add(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    history.remove(route.settings.name);
  }
}

FutureOr<String?> redirectRoutes(
    BuildContext context, GoRouterState state) async {
  Logger.info('Ubicación -> ${state.matchedLocation}');
  final auth = AuthStore.instance;

  if (!RouteNames.routesConfiguration.contains(state.matchedLocation)) {
    if (!auth.isLogged) {
      return '/${RouteNames.splashScreen}';
    }
  }
  return null;
}
