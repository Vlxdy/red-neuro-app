import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/features/comentarios/models/comentario_chat_models.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ComentariosService extends ServiceConfig {
  ComentariosService(BuildContext context) : super('', context);

  Future<ComentariosPaginados> obtenerComentarios(
    String idHistoriaClinica, {
    int pagina = 1,
    int limite = 20,
  }) async {
    final response = await fetch(
      '/historia-clinica/$idHistoriaClinica/comentarios',
      type: HttpProtocol.get,
      params: {
        'pagina': '$pagina',
        'limite': '$limite',
      },
    );

    if (response.status != StatusNetwork.connected) {
      throw ErrorDescription(response.message);
    }

    final data = response.data;
    final filas = (data['filas'] as List<dynamic>? ?? [])
        .map(
          (item) => ComentarioChat.fromJson(
            item as Map<String, dynamic>,
            historiaClinicaId: idHistoriaClinica,
            baseUrl: Constantes.apiUrl,
          ),
        )
        .toList();

    final total = data['total'] is int
        ? data['total'] as int
        : int.tryParse(data['total']?.toString() ?? '0') ?? filas.length;

    return ComentariosPaginados(
      comentarios: filas,
      total: total,
      pagina: pagina,
      limite: limite,
    );
  }

  Future<ComentarioChat> crearComentario({
    required String idHistoriaClinica,
    required String contenido,
    List<ComentarioArchivoLocal> archivos = const [],
  }) async {
    final respuesta = await _sendMultipart(
      '/historia-clinica/$idHistoriaClinica/comentarios',
      fields: {'contenido': contenido},
      archivos: archivos,
    );

    return ComentarioChat.fromJson(
      respuesta,
      historiaClinicaId: idHistoriaClinica,
      baseUrl: Constantes.apiUrl,
    );
  }

  Future<ComentarioChat> responderComentario({
    required String idComentario,
    required String contenido,
    List<ComentarioArchivoLocal> archivos = const [],
    String? historiaClinicaId,
  }) async {
    final respuesta = await _sendMultipart(
      '/comentarios/$idComentario/reply',
      fields: {'contenido': contenido},
      archivos: archivos,
    );

    return ComentarioChat.fromJson(
      respuesta,
      historiaClinicaId: historiaClinicaId,
      baseUrl: Constantes.apiUrl,
    );
  }

  Future<ComentarioChat> actualizarComentario({
    required String idComentario,
    required String contenido,
    String? historiaClinicaId,
  }) async {
    final response = await fetch(
      '/comentarios/$idComentario',
      type: HttpProtocol.patch,
      body: {'contenido': contenido},
    );

    if (response.status != StatusNetwork.connected) {
      throw ErrorDescription(response.message);
    }

    final datos = response.data.isEmpty
        ? {'id': idComentario, 'contenido': contenido}
        : response.data;

    return ComentarioChat.fromJson(
      datos,
      historiaClinicaId: historiaClinicaId,
      baseUrl: Constantes.apiUrl,
    );
  }

  Future<void> eliminarComentario(String idComentario) async {
    final response = await fetch(
      '/comentarios/$idComentario/inactivar',
      type: HttpProtocol.patch,
    );

    if (response.status != StatusNetwork.connected) {
      throw ErrorDescription(response.message);
    }
  }

  Future<Uint8List> descargarArchivo({
    required String url,
  }) async {
    final token = await Auth.instance.apiToken;
    final uri = Uri.parse(url);
    final headers = await getHeaders(
      withAuthorization: true,
      customToken: token,
      type: HttpTypeRequest.json,
    );

    final response = await http.get(uri, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ErrorDescription('No se pudo descargar el archivo');
  }

  Future<Map<String, dynamic>> _sendMultipart(
    String path, {
    required Map<String, String> fields,
    List<ComentarioArchivoLocal> archivos = const [],
  }) async {
    final uri = Uri.parse('${Constantes.apiUrl}$path');
    final headers = await getHeaders(
      withAuthorization: true,
      type: HttpTypeRequest.formdata,
    );

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);
    request.fields.addAll(fields);

    for (final archivo in archivos) {
      if (archivo.path == null) continue;
      final file = File(archivo.path!);
      if (!file.existsSync()) continue;
      final mimeType = archivo.mimeType ?? 'application/octet-stream';
      final mimeParts = mimeType.split('/');
      final multipartFile = await http.MultipartFile.fromPath(
        'archivos',
        file.path,
        filename: archivo.nombre,
        contentType: mimeParts.length == 2
            ? MediaType(mimeParts.first, mimeParts.last)
            : null,
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request
        .send()
        .timeout(const Duration(seconds: Constantes.timeout));
    final response = await http.Response.fromStream(streamedResponse);

    final status = decodeStatus(response.statusCode);
    validateResponse(status);

    final body = response.bodyBytes.isEmpty
        ? {}
        : json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (!context.mounted) {
      throw Exception('Context not found');
    }

    final Map<String, dynamic> rawBody = (body).cast<String, dynamic>();
    final parsed = parseResponse(rawBody, context, status: status);

    if (parsed['status'] != StatusNetwork.connected) {
      throw ErrorDescription(
          parsed['message']?.toString() ?? 'Error de servidor');
    }

    final datos = parsed['data'];
    if (datos is Map<String, dynamic>) {
      return datos;
    }

    return rawBody;
  }
}
