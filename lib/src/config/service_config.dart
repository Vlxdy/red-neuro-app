import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alimenta_app/src/config/form_controller.dart';
import 'package:alimenta_app/src/config/middleware.dart';
import 'package:alimenta_app/src/constants/constants.dart';
import 'package:alimenta_app/src/constants/network.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:alimenta_app/src/plugins/utils/connection.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

class ResponseApi {
  late StatusNetwork status;
  late Map<String, dynamic> data;
  late Map<String, dynamic>? log;
  late String message;

  ResponseApi(this.status, this.data, this.message, {this.log});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = status;
    data['response'] = data;
    data['message'] = message;
    return data;
  }
}

class ServiceConfig with Middleware, FormController {
  String urlBase;
  BuildContext context;
  ServiceConfig(this.urlBase, this.context);

  Future<Map<String, String>> getHeaders(
      {bool withAuthorization = true,
      String? customToken,
      HttpTypeRequest? type = HttpTypeRequest.json}) async {
    Map<String, String> headers = {};
    if (type == HttpTypeRequest.json) {
      headers['Content-Type'] = 'application/json';
    }
    if (type == HttpTypeRequest.formdata) {
      headers['Content-Type'] = 'multipart/form-data';
    }
    headers['Accept'] = 'application/json';
    if (withAuthorization) {
      final token = customToken ?? await Auth.instance.apiToken;
      final auth = ('Bearer $token').replaceAll('"', "");
      Logger.sesion(auth);
      headers['Authorization'] = auth;
    }
    return headers;
  }

  Future<ResponseApi> fetch(
    String urlRecipe, {
    HttpProtocol? type = HttpProtocol.get,
    Object? body,
    bool withAuthorization = true,
    String? customToken,
    Map<String, String>? params,
  }) async {
    if (!await Connection.hasInternetConnected()) {
      return ResponseApi(
        StatusNetwork.noInternet,
        {'message': 'No tienes conexión a internet'},
        'No tienes conexión a internet',
      );
    }

    StatusNetwork status = StatusNetwork.noContent;
    final Response response;

    // Construimos la URI incluyendo los parámetros
    final uri = Uri.parse('${Constantes.apiUrl}$urlRecipe')
        .replace(queryParameters: params);

    try {
      final headers = await getHeaders(
        withAuthorization: withAuthorization,
        customToken: customToken,
      );

      Logger.info(
        'Ejecutando>>>> $uri, body: $body, headers: $headers method: $type',
      );

      switch (type) {
        case HttpProtocol.get:
          response = await get(uri, headers: headers)
              .timeout(const Duration(seconds: Constantes.timeout));
          break;
        case HttpProtocol.post:
          response = await post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: Constantes.timeout));
          break;
        case HttpProtocol.patch:
          response = await patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: Constantes.timeout));
          break;
        case HttpProtocol.put:
          response = await put(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: Constantes.timeout));
          break;
        case HttpProtocol.delete:
          response = await delete(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: Constantes.timeout));
          break;
        default:
          response = await get(uri, headers: headers)
              .timeout(const Duration(seconds: Constantes.timeout));
          break;
      }

      final decode = utf8.decode(response.bodyBytes);
      final json = jsonDecode(decode);
      status = decodeStatus(response.statusCode);
      validateResponse(status);

      if (context.mounted) {
        final responseParsed = parseResponse(json, context);
        return ResponseApi(
          responseParsed['status'],
          responseParsed['data'],
          responseParsed['message'],
          log: json,
        );
      } else {
        throw Exception('Context not found');
      }
    } on TimeoutException catch (_) {
      return ResponseApi(
        StatusNetwork.timeout,
        {'message': 'Tiempo de espera excedido'},
        'Tiempo de espera excedido',
      );
    } catch (e) {
      Logger.error('exception fetch >>>> ${e.toString()}');
      return ResponseApi(
        StatusNetwork.exception,
        {'message': 'Ocurrió un error inesperado', 'log': e.toString()},
        'Ocurrió un error inesperado',
      );
    }
  }

  Future<ResponseApi> multipartRequest(String urlRecipe,
      {String type = 'POST',
      List<File>? files,
      List<String>? nameFiles,
      Map<String, dynamic>? body,
      bool image = true,
      bool withAuthorization = true,
      int timeout = Constantes.timeout}) async {
    Logger.info('Numero de items ${files?.length.toString()}');
    if (!(await Connection.hasInternetConnected())) {
      return ResponseApi(
          StatusNetwork.noInternet,
          {'message': 'No tienes conexión a internet'},
          'No tienes conexión a internet');
    }

    final headers = await getHeaders(
        withAuthorization: withAuthorization, type: HttpTypeRequest.formdata);

    StatusNetwork status = StatusNetwork.noContent;
    final Uri uri = Uri.parse('${Constantes.apiUrl}$urlBase$urlRecipe');
    var request = MultipartRequest(type, uri)..headers.addAll(headers);

    try {
      if (body != null) {
        body.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }
      if (files != null && files.isNotEmpty && nameFiles != null) {
        // files.length == nameFiles.length) {
        for (int i = 0; i < files.length; i++) {
          MultipartFile multiPartFile;
          if (image) {
            multiPartFile = MultipartFile(
              nameFiles[0],
              files[i].readAsBytes().asStream(),
              files[i].lengthSync(),
              filename: files[i].path.split('/').last,
              contentType: MediaType('image', 'jpg'),
            );
          } else {
            multiPartFile = MultipartFile(
              nameFiles[i],
              files[i].readAsBytes().asStream(),
              files[i].lengthSync(),
              filename: files[i].path.split('/').last,
            );
          }

          request.files.add(multiPartFile);
        }
      }
      Logger.info('Ejecutando>>>> $uri, body: $body, method: $type ');
      final response = await request.send().timeout(Duration(seconds: timeout));
      final decode = await response.stream.transform(utf8.decoder).join();
      final json = jsonDecode(decode);
      status = decodeStatus(response.statusCode);
      validateResponse(status);
      if (context.mounted) {
        final responseParsed = parseResponse(json, context, status: status);
        return ResponseApi(responseParsed['status'], responseParsed['data'],
            responseParsed['message'],
            log: json);
      } else {
        throw Exception('Context not found');
      }
    } on TimeoutException catch (_) {
      return ResponseApi(
          StatusNetwork.timeout,
          {'message': 'Tiempo de espera excedido'},
          'Tiempo de espera excedido');
    } catch (e, stacktrace) {
      Logger.error('exception fetch >>>> ${e.toString()}');
      Logger.error('stacktrace $stacktrace');
      return ResponseApi(
          StatusNetwork.exception,
          {'message': 'Ocurrió un error inesperado', 'log': e.toString()},
          'Ocurrió un error inesperado');
    }
  }

  Future<ResponseApi> multipartRequestFilesKeys(
    String urlRecipe, {
    String type = 'POST',
    Map<String, List<File>>? files,
    Map<String, dynamic>? body,
    bool image = true,
    bool withAuthorization = true,
    int timeout = Constantes.timeout,
  }) async {
    if (!(await Connection.hasInternetConnected())) {
      return ResponseApi(
        StatusNetwork.noInternet,
        {'message': 'No tienes conexión a internet'},
        'No tienes conexión a internet',
      );
    }

    final headers = await getHeaders(
      withAuthorization: withAuthorization,
      type: HttpTypeRequest.formdata,
    );

    final Uri uri = Uri.parse('${Constantes.apiUrl}$urlBase$urlRecipe');
    var request = MultipartRequest(type, uri)..headers.addAll(headers);

    try {
      // Agregar los campos del body si existen
      body?.forEach((key, value) {
        request.fields[key] = jsonEncode(value).toString();
      });

      // Añadir los archivos por tanque organizados
      if (files != null && files.isNotEmpty) {
        for (var key in files.keys) {
          for (var file in files[key]!) {
            var multipartFile = MultipartFile(
              key,
              file.readAsBytes().asStream(),
              file.lengthSync(),
              filename: file.path.split('/').last,
              contentType: MediaType('image', 'jpg'),
            );
            request.files.add(multipartFile);
            Logger.info(request.files.toString());
          }
        }
      }

      Logger.info('Ejecutando>>>> $uri, body: $body, method: $type');

      final response = await request.send().timeout(Duration(seconds: timeout));
      final decode = await response.stream.transform(utf8.decoder).join();
      final json = jsonDecode(decode);

      final status = decodeStatus(response.statusCode);
      validateResponse(status);

      if (context.mounted) {
        final responseParsed = parseResponse(json, context, status: status);
        return ResponseApi(
          responseParsed['status'],
          responseParsed['data'],
          responseParsed['message'],
          log: json,
        );
      } else {
        throw Exception('Context not found');
      }
    } on TimeoutException {
      return ResponseApi(
        StatusNetwork.timeout,
        {'message': 'Tiempo de espera excedido'},
        'Tiempo de espera excedido',
      );
    } catch (e, stacktrace) {
      Logger.error('Exception fetch >>>> ${e.toString()}');
      Logger.error('Stacktrace: $stacktrace');

      return ResponseApi(
        StatusNetwork.exception,
        {'message': 'Ocurrió un error inesperado', 'log': e.toString()},
        'Ocurrió un error inesperado',
      );
    }
  }

  Future<bool> hasInternetConnection() async {
    return await Connection.hasInternetConnected();
  }
}

enum HttpProtocol { get, post, patch, put, delete }

enum HttpTypeRequest { json, formdata }
