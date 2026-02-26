import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/models/estudio.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class EstudioPageResult {
  final List<Estudio> estudios;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const EstudioPageResult({
    required this.estudios,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory EstudioPageResult.empty(String message) => EstudioPageResult(
        estudios: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class EstudiosService extends ServiceConfig {
  EstudiosService(BuildContext context) : super('', context);

  Future<EstudioPageResult> obtenerEstudios({
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/servicios',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          'tipo': 'ESTUDIO',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );

      if (response.status != StatusNetwork.connected) {
        return EstudioPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final estudios = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Estudio.fromJson)
              .toList()
          : <Estudio>[];

      return EstudioPageResult(
        estudios: estudios,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? estudios.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar estudios $e');
      Logger.error('stacktrace $stacktrace');
      return EstudioPageResult.empty('No se pudieron cargar los estudios');
    }
  }

  Future<List<Especialidad>> obtenerEspecialidades() async {
    try {
      final response = await fetch(
        '/especialidades',
        params: {
          'pagina': '1',
          'limite': '50',
        },
      );

      if (response.status != StatusNetwork.connected) {
        return [];
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      if (filasRaw is List) {
        return filasRaw
            .whereType<Map<String, dynamic>>()
            .map(Especialidad.fromJson)
            .toList();
      }
    } catch (e, stacktrace) {
      Logger.error('Error al obtener especialidades $e');
      Logger.error('stacktrace $stacktrace');
    }
    return [];
  }

  Future<ResponseApi> crearEstudio(Map<String, dynamic> body) async {
    return fetch(
      '/servicios',
      type: HttpProtocol.post,
      body: {
        ...body,
        'tipo': 'ESTUDIO',
      },
    );
  }

  Future<ResponseApi> actualizarEstudio(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch(
      '/servicios/$id',
      type: HttpProtocol.patch,
      body: body,
    );
  }

  Future<ResponseApi> eliminarEstudio(String id) async {
    return fetch(
      '/servicios/$id',
      type: HttpProtocol.delete,
    );
  }

  Future<ResponseApi> cambiarEstadoEstudio(String id) async {
    return fetch(
      '/servicios/$id/cambiar-estado',
      type: HttpProtocol.patch,
    );
  }

  Future<ResponseApi> asignarEspecialidad({
    required String estudioId,
    required String especialidadId,
  }) async {
    return fetch(
      '/servicios/$estudioId/especialidades',
      type: HttpProtocol.post,
      body: {
        'especialidadId': especialidadId,
      },
    );
  }
}
