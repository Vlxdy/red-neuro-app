import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:flutter/material.dart';

class TemplatePage extends StatelessWidget {
  final Widget? page;
  final Widget? background;
  final Widget? customLoading;
  final BackgroundType typeAppBar;
  final Color? colorBackground;
  final bool cargando;
  final bool showEnvironmentBanner;
  const TemplatePage({
    super.key,
    this.page,
    this.background,
    this.customLoading,
    this.cargando = false,
    this.colorBackground,
    this.typeAppBar = BackgroundType.transparent,
    this.showEnvironmentBanner = true,
  });

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
    final String environment = Constantes.entorno;
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.brightness,
      builder: (BuildContext context, bool _, Widget? child) {
        final ThemeController theme = ThemeController.instance;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: theme.background,
            body: Stack(
              children: <Widget>[
                background ?? _TemplateDecorBackground(theme: theme),
                appBar(typeAppBar),
                page ?? const SizedBox(),
                cargando
                    ? customLoading != null
                          ? customLoading!
                          : Container(
                              color: theme.black.withValues(alpha: 0.26),
                              height: double.infinity,
                              width: double.infinity,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: theme.primary,
                                ),
                              ),
                            )
                    : const SizedBox(),
                showEnvironmentBanner && environment != 'PRODUCTION'
                    ? Banner(
                        location: BannerLocation.topStart,
                        message: environment,
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TemplateDecorBackground extends StatelessWidget {
  const _TemplateDecorBackground({required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, 1), // fondo exacto
            radius: 1.5,
            stops: const [0.0, 0.7],
            colors: [
              theme.primary.withValues(alpha: theme.isDark ? 0.05 : 0.002),
              theme.background,
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            _TemplateDecorBubble(
              top: -64,
              right: -36,
              size: 210,
              color: theme.primary.withValues(
                alpha: theme.isDark ? 0.060 : 0.048,
              ),
            ),
            _TemplateDecorBubble(
              top: 180,
              left: -72,
              size: 170,
              color: theme.secondary.withValues(
                alpha: theme.isDark ? 0.054 : 0.044,
              ),
            ),
            _TemplateDecorBubble(
              bottom: -88,
              right: -30,
              size: 230,
              color: theme.accent500.withValues(
                alpha: theme.isDark ? 0.058 : 0.046,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateDecorBubble extends StatelessWidget {
  const _TemplateDecorBubble({
    required this.size,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double size;
  final Color color;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

enum BackgroundType { transparent, blobs, waves, waves2 }
