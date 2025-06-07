import 'dart:io';
import 'package:collection/collection.dart';
import 'package:camino_seguro/src/plugins/camera/camera_screen_service.dart';
import 'package:camino_seguro/src/plugins/camera/camera_screen_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/ui/global/template_page.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GlobalKey<ScaffoldMessengerState> cameraScreenMessenger =
    GlobalKey<ScaffoldMessengerState>();

class CameraItem {
  CameraDescription? camera;
  bool active = false;
  CameraItem(this.camera, this.active);
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _cameraNotAvailable = false;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  late Future<void> _initializeControllerFuture;
  late File? _photo;
  List<CameraItem> backCameras = [];
  final cameraService = CameraScreenService();

  void _showCameraException(CameraException e) {
    cameraService.logError(e.code, e.description);
    _showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void _showInSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Expanded(child: Text(message)), const Icon(Icons.error)]),
      backgroundColor: Colors.orange,
    ));
  }

  void _initCamera(CameraDescription? cameraDescription) async {
    try {
      _controller = CameraController(
          cameraDescription!, ResolutionPreset.veryHigh,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      _controller.addListener(() {
        if (mounted) setState(() {});
        if (_controller.value.hasError) {
          throw ErrorDescription(
              'Error Camera: ${_controller.value.errorDescription}');
        }
      });
      _initializeControllerFuture = _controller.initialize().then((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _isInitialized = true;
        });
      });
    } catch (e) {
      _showInSnackBar('Error Camera: $e');
    }
  }

  Future<XFile?> _takePicture() async {
    if (!_controller.value.isInitialized) {
      Logger.warning('Controlador de cámara no inicializado');
      return null;
    }
    if (_controller.value.isTakingPicture) {
      Logger.warning('Ya se está tomando una foto');
      return null;
    }

    try {
      return await _controller.takePicture();
    } on CameraException catch (e) {
      _showCameraException(e);
      throw Error();
    }
  }

  @override
  void initState() {
    super.initState();
    _photo = null;
    availableCameras().then((cameras) {
      if (cameras.isEmpty) {
        return <CameraItem>[];
      }
      return cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .map((camera) => CameraItem(camera, false))
          .toList();
    }).then((cameras) {
      if (cameras.isEmpty) {
        setState(() {
          _cameraNotAvailable = true;
        });
        return;
      }
      setState(() {
        backCameras = cameras;
        backCameras.first.active = true;
      });
      _initCamera(backCameras.first.camera);
    });
  }

  void _onTakePictureButtonPress(ScreenInfo screenInfo) async {
    if (!_isInitialized || _isTakingPicture) return;
    _isTakingPicture = true;
    final XFile? xFileImage = await _takePicture();
    if (xFileImage != null) {
      File newCameraImage =
          await cameraService.processImage(xFileImage, screenInfo);
      setState(() {
        _photo = newCameraImage;
      });
    }
    _isTakingPicture = false;
  }

  @override
  void dispose() {
    if (!_cameraNotAvailable) {
      _controller.dispose();
    }
    super.dispose();
  }

  void setCameraActive(int index) {
    for (var item in backCameras) {
      item.active = false;
    }
    setState(() {
      backCameras[index].active = true;
    });
  }

  Widget iconCameras(CameraScreenStore cameraStore) {
    if (backCameras.isEmpty || cameraStore.cargando) return const SizedBox();
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: backCameras
            .mapIndexed((index, camera) => IconButton(
                  padding: const EdgeInsets.only(bottom: 15),
                  constraints: const BoxConstraints(),
                  iconSize: 50,
                  icon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        backCameras[index].camera!.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: backCameras[index].active
                              ? ThemeController.instance.neutral
                              : ThemeController.instance.white,
                        ),
                      ),
                      Icon(
                        CupertinoIcons.camera_circle,
                        color: backCameras[index].active
                            ? ThemeController.instance.neutral
                            : ThemeController.instance.white,
                      ),
                    ],
                  ),
                  onPressed: () {
                    setCameraActive(index);
                    Logger.info('camera button pressed: $index');
                    _initCamera(backCameras[index].camera);
                  },
                ))
            .toList());
  }

  Widget showPosition(CameraScreenStore cameraStore) {
    var children = <Widget>[];
    if (cameraStore.cargando) {
      children = [
        Text(
          'Obteniendo ubicación...',
          style: getStyle(bold: true),
        )
      ];
    } else {
      children = cameraStore.posicion == null
          ? [
              Text(
                'No se pudo obtener la posición!',
                style: getStyle(bold: true),
              )
            ]
          : [
              Row(
                children: [
                  Text('Latitud: ',
                      style: getStyle(underline: true, bold: true)),
                  Text(
                    '${cameraStore.posicion?.latitude ?? '---'}',
                    style: getStyle(),
                  )
                ],
              ),
              Row(
                children: [
                  Text('Longitud: ',
                      style: getStyle(underline: true, bold: true)),
                  Text(
                    '${cameraStore.posicion?.longitude ?? '---'}',
                    style: getStyle(),
                  )
                ],
              )
            ];
    }
    children.insert(0, const SizedBox(height: 10));
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        children: children,
      ),
    );
  }

  TextStyle getStyle({bool underline = false, bool bold = false}) => TextStyle(
      fontFamily: 'OpenSans',
      color: Colors.white.withOpacity(!_isInitialized ? 0.5 : 1),
      fontSize: 16,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      decoration: underline ? TextDecoration.underline : TextDecoration.none);

  List<Widget> showShutter(CameraScreenStore cameraStore, Size size) {
    double widgetSize = size.height * 0.13;
    if (cameraStore.cargando) {
      return [
        SizedBox(
            height: widgetSize,
            width: widgetSize,
            child: CircularProgressIndicator(
                color: Colors.white.withOpacity(!_isInitialized ? 0.5 : 1)))
      ];
    }
    return [
      Container(
        height: size.height * 0.13,
        width: size.height * 0.13,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withOpacity(!_isInitialized ? 0.5 : 1),
                width: 3)),
      ),
      Container(
        height: size.height * 0.10,
        width: size.height * 0.10,
        margin: EdgeInsets.all(size.height * 0.015),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(!_isInitialized ? 0.5 : 1)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final size = MediaQuery.of(context).size;
    final screenInfo =
        ScreenInfo(MediaQuery.of(context).devicePixelRatio, size);
    final cameraStore = context.watch<CameraScreenStore>();

    if (_cameraNotAvailable) {
      const center = Center(
        child: Text('Cámara no disponible'),
      );

      return Scaffold(
        appBar: AppBar(),
        body: center,
      );
    }

    final stack = _photo == null
        ? Stack(
            children: <Widget>[
              _isInitialized
                  ? Container(
                      height: size.height,
                      width: size.width,
                      color: Colors.black,
                      child: FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: CameraPreview(_controller),
                            );
                          } else {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        },
                      ))
                  : Container(
                      height: size.height,
                      width: size.width,
                      color: Colors.black,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(
                            color: theme.warning,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Text(
                            'Inicializando la cámara...',
                            style: TextStyle(color: theme.white),
                          )
                        ],
                      ),
                    ),
              Stack(
                children: [
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: EdgeInsets.only(bottom: size.height * 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            GestureDetector(
                                onTap: () =>
                                    _isInitialized && !cameraStore.cargando
                                        ? _onTakePictureButtonPress(screenInfo)
                                        : null,
                                child: Stack(
                                  children: showShutter(cameraStore, size),
                                )),
                            SizedBox(height: size.height * 0.01),
                            !cameraStore.cargando
                                ? Text('Tomar foto', style: getStyle())
                                : const SizedBox(),
                          ],
                        ),
                      )),
                  backCameras.length > 1
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: iconCameras(cameraStore),
                        )
                      : const SizedBox(),
                  showPosition(cameraStore)
                ],
              ),
            ],
          )
        : Stack(children: <Widget>[
            SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: Image.file(File(_photo!.path)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(
                  bottom: size.height * 0.05,
                  left: 10,
                  right: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    InkWell(
                      onTap: () async {
                        /// Eliminar la foto que ha sido tomada
                        await _photo!.delete();
                        if (!context.mounted) return;
                        if (context.mounted) {
                          setState(() {
                            _photo = null;
                          });
                        }
                      },
                      child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(50)),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 40,
                          )),
                    ),
                    InkWell(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(50)),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        onTap: () {
                          Logger.info(
                              'Ruta de la foto tomada : : ${_photo!.path}');
                          context.pop(_photo!.path);
                        })
                  ],
                ),
              ),
            ),
          ]);

    return TemplatePage(
        page: ScaffoldMessenger(
            key: cameraScreenMessenger,
            child: Scaffold(
                appBar: AppBar(
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  systemOverlayStyle: SystemUiOverlayStyle(
                      statusBarBrightness:
                          theme.isDark ? Brightness.dark : Brightness.light,
                      statusBarColor: theme.transparent),
                  backgroundColor: theme.transparent,
                  centerTitle: false,
                  leading: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                  title: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fotografía de respaldo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                backgroundColor: theme.transparent,
                body: stack)));
  }
}
