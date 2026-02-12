// import 'package:red_neuro_app/src/plugins/camera/camera_screen_store.dart';
import 'package:red_neuro_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena_store.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_store.dart';
import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/ui/global/loading_animation.dart';
import 'package:red_neuro_app/src/ui/pages/login/login_store.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> proveedores(BuildContext context) => [
  ChangeNotifierProvider(create: (context) => LoadingAnimation.instance),
  ChangeNotifierProvider(create: (context) => LoginStore.instance),
  ChangeNotifierProvider(create: (context) => CambiarContrasenaStore.instance),
  ChangeNotifierProvider(create: (context) => CodigoPinStore.instance),

  // ChangeNotifierProvider(create: (context) => CameraScreenStore.instance),
];

void resetProviders() {}
