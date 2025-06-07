import 'package:camino_seguro/src/plugins/camera/camera_screen_store.dart';
import 'package:camino_seguro/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:camino_seguro/src/ui/pages/cambiar_contrasena/cambiar_contrasena_store.dart';
import 'package:camino_seguro/src/ui/pages/control/control_store.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/stores/registro_dependientes_store.dart';
import 'package:camino_seguro/src/ui/pages/inicio/inicio_store.dart';
import 'package:camino_seguro/src/ui/pages/principal_page/principal_page_store.dart';
import 'package:flutter/material.dart';
import 'package:camino_seguro/src/ui/global/loading_animation.dart';
import 'package:camino_seguro/src/ui/pages/login/login_store.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> proveedores(BuildContext context) => [
      ChangeNotifierProvider(create: (context) => LoadingAnimation.instance),
      ChangeNotifierProvider(create: (context) => LoginStore.instance),
      ChangeNotifierProvider(
          create: (context) => CambiarContrasenaStore.instance),
      ChangeNotifierProvider(create: (context) => PrincipalPageStore.instance),
      ChangeNotifierProvider(create: (context) => CodigoPinStore.instance),
      ChangeNotifierProvider(create: (context) => CameraScreenStore.instance),
      // eliminar
      ChangeNotifierProvider(create: (context) => ControlStore.instance),
      ChangeNotifierProvider(create: (context) => RegistroAreasStore.instance),
      ChangeNotifierProvider(
          create: (context) => RegistroDependientesStore.instance),
    ];

resetProviders() {
  // TODO: pendiente limpiar providers
}
