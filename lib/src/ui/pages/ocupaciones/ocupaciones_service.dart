import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/ocupacion.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class OcupacionPageResult {
  final List<Ocupacion> ocupaciones;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const OcupacionPageResult({
    required this.ocupaciones,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory OcupacionPageResult.empty(String message) => OcupacionPageResult(
        ocupaciones: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class OcupacionesService extends ServiceConfig {
  OcupacionesService(BuildContext context) : super('', context);

  Future<OcupacionPageResult> obtenerOcupaciones({
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/ocupaciones',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );

      if (response.status != StatusNetwork.connected) {
        return OcupacionPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final ocupaciones = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Ocupacion.fromJson)
              .toList()
          : <Ocupacion>[];

      return OcupacionPageResult(
        ocupaciones: ocupaciones,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? ocupaciones.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar ocupaciones $e');
      Logger.error('stacktrace $stacktrace');
      return OcupacionPageResult.empty('No se pudieron cargar las ocupaciones');
    }
  }

  Future<ResponseApi> crearOcupacion(Map<String, dynamic> body) async {
    return fetch('/ocupaciones', type: HttpProtocol.post, body: body);
  }

  Future<ResponseApi> actualizarOcupacion(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch('/ocupaciones/$id', type: HttpProtocol.patch, body: body);
  }

  Future<ResponseApi> eliminarOcupacion(String id) async {
    return fetch('/ocupaciones/$id', type: HttpProtocol.delete);
  }

  Future<ResponseApi> cambiarEstadoOcupacion(String id) async {
    return fetch('/ocupaciones/$id/cambiar-estado', type: HttpProtocol.patch);
  }
}
