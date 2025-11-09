import 'package:alimenta_app/src/plugins/camera/camera_screen_store.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/stores/citas_medicas_store.dart';
import 'package:alimenta_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena_store.dart';
import 'package:alimenta_app/src/ui/pages/plan_nutricional/stores/plan_nutricional_store.dart';
import 'package:alimenta_app/src/ui/pages/inicio/inicio_store.dart';
import 'package:flutter/material.dart';
import 'package:alimenta_app/src/ui/global/loading_animation.dart';
import 'package:alimenta_app/src/ui/pages/login/login_store.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> proveedores(BuildContext context) => [
      ChangeNotifierProvider(create: (context) => LoadingAnimation.instance),
      ChangeNotifierProvider(create: (context) => LoginStore.instance),
      ChangeNotifierProvider(
          create: (context) => CambiarContrasenaStore.instance),
      ChangeNotifierProvider(create: (context) => CodigoPinStore.instance),
      ChangeNotifierProvider(create: (context) => CameraScreenStore.instance),
      ChangeNotifierProvider(create: (context) => CitasMedicasStore.instance),
      ChangeNotifierProvider(
          create: (context) => PlanNutricionalStore.instance),
    ];

resetProviders() {}
