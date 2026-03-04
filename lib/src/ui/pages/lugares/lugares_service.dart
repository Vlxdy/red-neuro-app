import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/lugar.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class LugaresPageResult {
  final List<Lugar> lugares;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const LugaresPageResult({
    required this.lugares,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory LugaresPageResult.empty(String message) => LugaresPageResult(
        lugares: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class LugaresService extends ServiceConfig {
  LugaresService(BuildContext context) : super('', context);

  Future<LugaresPageResult> obtenerLugares({
    int page = 1,
    int limit = 10,
    String? filtro,
    String? ordenRaw,
  }) async {
    try {
      final response = await fetch(
        '/lugares',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
          if (ordenRaw != null && ordenRaw.isNotEmpty) 'ordenRaw': ordenRaw,
        },
      );

      if (response.status != StatusNetwork.connected) {
        return LugaresPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final lugares = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Lugar.fromJson)
              .toList()
          : <Lugar>[];

      return LugaresPageResult(
        lugares: lugares,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? lugares.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar lugares $e');
      Logger.error('stacktrace $stacktrace');
      return LugaresPageResult.empty('No se pudieron cargar los lugares');
    }
  }

  Future<ResponseApi> crearLugar(Map<String, dynamic> body) async {
    return fetch('/lugares', type: HttpProtocol.post, body: body);
  }

  Future<ResponseApi> actualizarLugar(String id, Map<String, dynamic> body) async {
    return fetch('/lugares/$id', type: HttpProtocol.patch, body: body);
  }

  Future<ResponseApi> cambiarEstadoLugar(String id) async {
    return fetch('/lugares/$id/cambiar-estado', type: HttpProtocol.patch);
  }
}
