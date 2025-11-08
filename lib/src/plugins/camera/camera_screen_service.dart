import 'dart:io';
import 'dart:ui';

import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/constants/constants.dart';
import 'package:alimenta_app/src/plugins/camera/camera_screen_store.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_editor/image_editor.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImagePaths {
  String filePath;
  String filePathCompressed;
  ImagePaths(this.filePath, this.filePathCompressed);
}

class ScreenInfo {
  double devicePixelRatio;
  Size size;
  ScreenInfo(this.devicePixelRatio, this.size);
  ScreenInfo.fromObject(ScreenInfo screenInfo)
      : this(screenInfo.devicePixelRatio, screenInfo.size);
}

class CameraScreenService {
  final store = CameraScreenStore.instance;
  late ScreenInfo _screenInfo;

  void logError(String code, String? message) =>
      Logger.error('LogError: $code | message: $message');

  String _timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<ImagePaths> _getImagePaths() async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dirPath = path.join(docsDir.path, 'DataLince');
    await Directory(dirPath).create(recursive: true);
    String fileName = _timestamp();
    final String filePath = path.join(dirPath, '$fileName.jpg');
    final String filePathCompressed =
        path.join(dirPath, '$fileName-compressed.jpg');
    return ImagePaths(filePath, filePathCompressed);
  }

  Future<File> _compressImage(
      String pathImage, String filePathCompressed) async {
    int imageCompressionQuality =
        int.tryParse(Constantes.imageCompressionQuality) ?? 30;
    var xFileCompressed = await FlutterImageCompress.compressAndGetFile(
        pathImage, filePathCompressed,
        quality: imageCompressionQuality, format: CompressFormat.jpeg);
    final File fileCompressed = File(xFileCompressed!.path);
    Logger.info(
        "tam. comprimido: ${(fileCompressed.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB");
    return fileCompressed;
  }

  Future<File> processImage(XFile xFileImage, ScreenInfo screenInfo) async {
    _screenInfo = ScreenInfo.fromObject(screenInfo);
    String pathImage = xFileImage.path;
    final paths = await _getImagePaths();
    File fileCompressed =
        await _compressImage(pathImage, paths.filePathCompressed);
    if (store.posicion != null) {
      final imageEdited =
          await _putCoordinates(fileCompressed, store.posicion!);
      if (imageEdited != null) {
        File newEditedImage = await imageEdited.rename(paths.filePath);
        return newEditedImage;
      }
    }
    File newCameraImage = await fileCompressed.rename(paths.filePath);
    Logger.info('NewCameraImage path :: ${newCameraImage.path}');
    return newCameraImage;
  }

  Future<File?> _putCoordinates(
    File image,
    Position position,
  ) async {
    final textOptionLat = AddTextOption();
    final textLat = 'Latitud: ${position.latitude}';
    final textLon = 'Longitud: ${position.longitude}';
    textOptionLat.addText(EditorText(
        text: textLat,
        offset: Offset(1, getPixel(1, getDouble: true)),
        fontSizePx: getPixel(25),
        textColor: ThemeController.instance.white,
        textAlign: TextAlign.left));
    final textOptionLon = AddTextOption();
    textOptionLon.addText(EditorText(
        text: textLon,
        offset: Offset(1, getPixel(15, getDouble: true)),
        fontSizePx: getPixel(25),
        textColor: ThemeController.instance.white,
        textAlign: TextAlign.left));
    final dimRect = getMaxLengthStr(textLat, textLon);
    final rectPart = RectDrawPart(
        rect: Rect.fromPoints(
            const Offset(1, 1),
            Offset(getPixel(dimRect * 13, getDouble: true),
                getPixel(60, getDouble: true))),
        paint: DrawPaint(
            color: ThemeController.instance.black,
            paintingStyle: PaintingStyle.fill));
    final imageOption = ImageEditorOption();
    imageOption.addOptions([
      DrawOption()..addDrawPart(rectPart),
      textOptionLat,
      textOptionLon,
    ]);
    try {
      final result = await ImageEditor.editImageAndGetFile(
          image: await image.readAsBytes(), imageEditorOption: imageOption);
      await File(image.path).delete();
      return result;
    } catch (e) {
      Logger.error('error editando imagen: $e');
      return null;
    }
  }

  int getMaxLengthStr(String str1, String str2) {
    return str1.length > str2.length ? str1.length : str2.length;
  }

  dynamic getPixel(int dim, {bool getDouble = false}) {
    final result = dim * _screenInfo.devicePixelRatio;
    return getDouble ? result : result.round();
  }
}
