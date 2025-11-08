import 'dart:convert';
import 'dart:io';

import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

enum FileExtensions { png, jpg, pdf }

class Finder {
  Future<void> listAllFiles(String path) async {
    try {
      final Directory docsDir = await getApplicationDocumentsDirectory();
      final directory = Directory('${docsDir.path}$path');

      if (await directory.exists()) {
        final files = directory.listSync();

        for (var file in files) {
          Logger.warning(file.path);
        }
      } else {
        Logger.warning("El directorio no existe.");
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al borrar documentos $e');
      Logger.error('stacktrace $stacktrace');
    }
  }

  Future<void> clearAllFiles(String path) async {
    try {
      final Directory docsDir = await getApplicationDocumentsDirectory();
      final directory = Directory('${docsDir.path}$path');

      if (await directory.exists()) {
        final files = directory.listSync();

        for (var file in files) {
          if (file is File) {
            await file.delete();
          } else if (file is Directory) {
            await file.delete(recursive: true);
          }
        }
        Logger.info("Todos los archivos han sido eliminados de $directory.");
      } else {
        Logger.warning("El directorio no existe.");
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al borrar documentos $e');
      Logger.error('stacktrace $stacktrace');
    }
  }

  Future<String?> saveFileFromb64(String name, String b64,
      {FileExtensions extension = FileExtensions.pdf}) async {
    String? path;
    String cleanName = name.trim().replaceAll(' ', '_');
    try {
      final Directory docsDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${docsDir.path}/Documentos';
      await Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/$cleanName.${extension.name}';

      final bytes = base64Decode(b64);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      path = filePath;
    } catch (e, stacktrace) {
      Logger.error('Exception al guardar documento $e');
      Logger.error('stacktrace $stacktrace');
    }
    return path;
  }
}
