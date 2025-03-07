import 'package:control_ventas_movil/src/plugins/camera/camera_screen_store.dart';
import 'package:control_ventas_movil/src/ui/pages/cambiar_contrasena/cambiar_contrasena_store.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_store.dart';
import 'package:control_ventas_movil/src/ui/pages/inicio/inicio_store.dart';
import 'package:control_ventas_movil/src/ui/pages/principal_page/principal_page_store.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/registrar_venta_store.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia_store.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';
import 'package:control_ventas_movil/src/ui/pages/login/login_store.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/registro_meters_store.dart';

List<SingleChildWidget> proveedores(BuildContext context) => [
      ChangeNotifierProvider(create: (context) => LoadingAnimation.instance),
      ChangeNotifierProvider(create: (context) => LoginStore.instance),
      ChangeNotifierProvider(
          create: (context) => CambiarContrasenaStore.instance),
      ChangeNotifierProvider(create: (context) => PrincipalPageStore.instance),
      ChangeNotifierProvider(create: (context) => CodigoPinStore.instance),
      ChangeNotifierProvider(create: (context) => RegistrarVentaStore.instance),
      ChangeNotifierProvider(create: (context) => CameraScreenStore.instance),
      ChangeNotifierProvider(create: (context) => ControlStore.instance),
      ChangeNotifierProvider(create: (context) => RegistroMetersStore.instance),
      ChangeNotifierProvider(create: (context) => ResumenDiaStore.instance),
      ChangeNotifierProvider(
          create: (context) => DataListadoMetersStore.instance),
    ];

resetProviders() {
  // TODO: pendiente limpiar providers
}
