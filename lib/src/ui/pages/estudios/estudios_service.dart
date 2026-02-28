import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/models/estudio.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class ServicioPageResult {
  final List<Servicio> servicios;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const ServicioPageResult({
    required this.servicios,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory ServicioPageResult.empty(String message) => ServicioPageResult(
        servicios: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class EspecialidadPageResult {
  final List<Especialidad> items;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const EspecialidadPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory EspecialidadPageResult.empty(String message) => EspecialidadPageResult(
        items: const [],
        total: 0,
        page: 1,
        limit: 20,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class EstudiosService extends ServiceConfig {
  EstudiosService(BuildContext context) : super('', context);

  Future<ServicioPageResult> obtenerServicios({
    int page = 1,
    int limit = 10,
    String? filtro,
    String? tipo,
  }) async {
    try {
      final response = await fetch(
        '/servicios',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );

      if (response.status != StatusNetwork.connected) {
        return ServicioPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final servicios = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Servicio.fromJson)
              .toList()
          : <Servicio>[];

      return ServicioPageResult(
        servicios: servicios,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? servicios.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar servicios $e');
      Logger.error('stacktrace $stacktrace');
      return ServicioPageResult.empty('No se pudieron cargar los servicios');
    }
  }

  @Deprecated('Usar obtenerServicios')
  Future<ServicioPageResult> obtenerEstudios({
    int page = 1,
    int limit = 10,
    String? filtro,
    String? tipo,
  }) => obtenerServicios(
        page: page,
        limit: limit,
        filtro: filtro,
        tipo: tipo,
      );

  Future<EspecialidadPageResult> obtenerEspecialidadesPaginadas({
    int page = 1,
    int limit = 20,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/especialidades',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.trim().isNotEmpty) 'filtro': filtro.trim(),
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
        items: especialidades,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? especialidades.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener especialidades $e');
      Logger.error('stacktrace $stacktrace');
      return EspecialidadPageResult.empty(
        'No se pudieron cargar las especialidades',
      );
    }
  }

  Future<List<Especialidad>> obtenerEspecialidades() async {
    final result = await obtenerEspecialidadesPaginadas(page: 1, limit: 50);
    return result.items;
  }

  Future<ResponseApi> crearServicio(Map<String, dynamic> body) async {
    return fetch(
      '/servicios',
      type: HttpProtocol.post,
      body: body,
    );
  }

  Future<ResponseApi> actualizarServicio(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch(
      '/servicios/$id',
      type: HttpProtocol.patch,
      body: body,
    );
  }

  Future<ResponseApi> eliminarServicio(String id) async {
    return fetch(
      '/servicios/$id',
      type: HttpProtocol.delete,
    );
  }

  Future<ResponseApi> cambiarEstadoServicio(String id) async {
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

  @Deprecated('Usar crearServicio')
  Future<ResponseApi> crearEstudio(Map<String, dynamic> body) =>
      crearServicio(body);

  @Deprecated('Usar actualizarServicio')
  Future<ResponseApi> actualizarEstudio(String id, Map<String, dynamic> body) =>
      actualizarServicio(id, body);

  @Deprecated('Usar eliminarServicio')
  Future<ResponseApi> eliminarEstudio(String id) => eliminarServicio(id);

  @Deprecated('Usar cambiarEstadoServicio')
  Future<ResponseApi> cambiarEstadoEstudio(String id) =>
      cambiarEstadoServicio(id);
}
