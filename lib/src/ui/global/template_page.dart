import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/constants.dart';
import 'package:flutter/material.dart';

class TemplatePage extends StatelessWidget {
  final Widget? page;
  final Widget? background;
  final Widget? customLoading;
  final BackgroundType typeAppBar;
  final Color? colorBackground;
  final bool cargando;
  const TemplatePage(
      {super.key,
      this.page,
      this.background,
      this.customLoading,
      this.cargando = false,
      this.colorBackground,
      this.typeAppBar = BackgroundType.transparent});

  Widget appBar(BackgroundType type) {
    // final theme = ThemeController.instance;
    switch (type) {
      case BackgroundType.transparent:
        return const SizedBox();
      // case BackgroundType.blobs:
      //   return Blobs(color: colorBackground ?? theme.primary50);
      // case BackgroundType.waves:
      //   return ClipPathAppBar(color: colorBackground ?? theme.primary);
      // case BackgroundType.waves2:
      //   return ClipPath2AppBar(color: colorBackground ?? theme.primary);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final environment = Constantes.entorno;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.background,
        body: Stack(
          children: [
            background ?? const SizedBox(),
            appBar(typeAppBar),
            page ?? const SizedBox(),
            cargando
                ? customLoading != null
                    ? customLoading!
                    : Container(
                        color: Colors.black26,
                        height: double.infinity,
                        width: double.infinity,
                        child: Center(
                          child:
                              CircularProgressIndicator(color: theme.primary),
                        ),
                      )
                : const SizedBox(),
            environment != 'PRODUCTION'
                ? Banner(
                    location: BannerLocation.topStart, message: environment)
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}

enum BackgroundType { transparent, blobs, waves, waves2 }
