import 'dart:io';

import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
// import 'package:red_neuro_app/src/plugins/geolocation/geolocation.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:red_neuro_app/src/ui/common/components/image_preview.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MultipleCampoFotografia extends StatelessWidget {
  final List<String> paths;
  final String titulo;
  final Function(List<String> paths) onClick;
  final Function(int index) onDelete;
  final int max;
  const MultipleCampoFotografia(
      {super.key,
      required this.titulo,
      required this.onClick,
      required this.onDelete,
      this.max = 10,
      required this.paths});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$titulo (Max $max)',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: theme.grey),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Container(
                width: 120,
                margin: const EdgeInsets.only(right: 8),
                height: 120,
                decoration: BoxDecoration(
                    border: Border.all(color: theme.grey),
                    borderRadius: BorderRadius.circular(4.0)),
                child: paths.isNotEmpty
                    ? Stack(
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: Image.file(
                              File(paths[0]),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 35,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(4.0),
                                  bottomRight: Radius.circular(4.0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: <Widget>[
                                  IconButton(
                                      onPressed: () {
                                        Logger.info('Vista previa foto 0');
                                        showDialog(
                                          context: context,
                                          builder: (_) => ImagePreviewDialog(
                                              imagePath: paths[0]),
                                        );
                                      },
                                      icon: Icon(Icons.remove_red_eye_rounded,
                                          size: 16, color: theme.white)),
                                  IconButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return Dialog(
                                                child: ConfirmationDialog(
                                                  title: 'Eliminar fotografía',
                                                  icon: Icons
                                                      .delete_forever_outlined,
                                                  color: theme.error,
                                                  onConfirm: () => onDelete(0),
                                                ),
                                              );
                                            });
                                      },
                                      icon: Icon(Icons.delete_outline_rounded,
                                          size: 16, color: theme.error)),
                                ],
                              ),
                            ),
                          )
                        ],
                      )
                    : InkWell(
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          // Geolocation.instance.getCurrentLocation();
                          final result = await context
                              .pushNamed<String>(RouteNames.vistaCamara);
                          if (result != null) {
                            if (paths.length <= max) {
                              paths.add(result);
                              Logger.info("> respaldo tomado: $result");
                              onClick(paths);
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: theme.grey),
                              Text(
                                titulo,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: theme.grey),
                              )
                            ],
                          ),
                        ),
                      ),
              ),
              if (paths.length > 1)
                for (int index = 0; index < paths.length; index++)
                  if (index != 0)
                    Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        height: 120,
                        decoration: BoxDecoration(
                            border: Border.all(color: theme.grey),
                            borderRadius: BorderRadius.circular(4.0)),
                        child: Stack(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Image.file(
                                File(paths[index]),
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 35,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(
                                      0.5), // Fondo semitransparente
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(4.0),
                                    bottomRight: Radius.circular(4.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    IconButton(
                                        onPressed: () {
                                          Logger.info(
                                              'Vista previa foto $index');
                                          showDialog(
                                            context: context,
                                            builder: (_) => ImagePreviewDialog(
                                                imagePath: paths[index]),
                                          );
                                        },
                                        icon: Icon(Icons.remove_red_eye_rounded,
                                            size: 16, color: theme.white)),
                                    // const SizedBox(width: 5),
                                    IconButton(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return Dialog(
                                                  child: ConfirmationDialog(
                                                    icon: Icons.delete_outline,
                                                    color: theme.error,
                                                    title:
                                                        'Eliminar fotografía',
                                                    onConfirm: () =>
                                                        onDelete(index),
                                                  ),
                                                );
                                              });
                                        },
                                        icon: Icon(Icons.delete_outline_rounded,
                                            size: 16, color: theme.error)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        )),
              paths.length < max
                  ? InkWell(
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        // Geolocation.instance.getCurrentLocation();
                        final result = await context
                            .pushNamed<String>(RouteNames.vistaCamara);
                        if (result != null) {
                          if (paths.length <= max) {
                            paths.add(result);
                            Logger.info("> respaldo tomado: $result");
                            onClick(paths);
                          }
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                            border: Border.all(color: theme.primary),
                            borderRadius: BorderRadius.circular(4.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: theme.primary, size: 32),
                              Text(
                                'Agregar foto',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: theme.primary),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        )
      ],
    );
  }
}
