import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class EspecialidadPageResult {
  final List<Especialidad> especialidades;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const EspecialidadPageResult({
    required this.especialidades,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory EspecialidadPageResult.empty(String message) => EspecialidadPageResult(
        especialidades: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class EspecialidadesService extends ServiceConfig {
  EspecialidadesService(BuildContext context) : super('', context);

  Future<EspecialidadPageResult> obtenerEspecialidades({
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/especialidades',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );

      if (response.status != StatusNetwork.connected) {
        return EspecialidadPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final especialidades = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Especialidad.fromJson)
              .toList()
          : <Especialidad>[];

      return EspecialidadPageResult(
        especialidades: especialidades,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? especialidades.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar especialidades $e');
      Logger.error('stacktrace $stacktrace');
      return EspecialidadPageResult.empty(
        'No se pudieron cargar las especialidades',
      );
    }
  }

  Future<ResponseApi> crearEspecialidad(Map<String, dynamic> body) async {
    return fetch(
      '/especialidades',
      type: HttpProtocol.post,
      body: body,
    );
  }

  Future<ResponseApi> actualizarEspecialidad(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch(
      '/especialidades/$id',
      type: HttpProtocol.patch,
      body: body,
    );
  }

  Future<ResponseApi> eliminarEspecialidad(String id) async {
    return fetch(
      '/especialidades/$id',
      type: HttpProtocol.delete,
    );
  }

  Future<ResponseApi> cambiarEstadoEspecialidad(String id) async {
    return fetch(
      '/especialidades/$id/cambiar-estado',
      type: HttpProtocol.patch,
    );
  }
}
