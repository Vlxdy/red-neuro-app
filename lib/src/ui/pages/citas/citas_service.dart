import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class CitasService extends ServiceConfig {
  CitasService(BuildContext context) : super('', context);

  Future<List<CitaMedica>> obtenerCitas({
    bool soloMisCitas = false,
    Map<String, String>? filtros,
  }) async {
    try {
      final response = await fetch(
        soloMisCitas ? '/citas/mis-citas' : '/citas',
        params: filtros,
      );

      if (response.status != StatusNetwork.connected) {
        return [];
      }

      final raw = response.data['datos'] ??
          response.data['data'] ??
          response.data['list'] ??
          response.data['items'] ??
          [];

      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(CitaMedica.fromJson)
            .toList();
      }
    } catch (e, stacktrace) {
      Logger.error('Error al obtener citas $e');
      Logger.error('stacktrace $stacktrace');
    }
    return [];
  }

  Future<CitasPageResult> obtenerCitasPaginadas({
    bool soloMisCitas = false,
    int page = 1,
    int limit = 10,
    Map<String, String>? filtros,
  }) async {
    try {
      final params = <String, String>{
        'pagina': '$page',
        'limite': '$limit',
        if (filtros != null) ...filtros,
      };

      final response = await fetch(
        soloMisCitas ? '/citas/mis-citas' : '/citas',
        params: params,
      );

      final status = response.status;
      final message = response.message;

      final data = response.data;
      final meta = data['meta'] ?? data['paginacion'] ?? {};
      final total = meta['totalRegistros'] ?? meta['total'] ?? data['total'] ?? 0;
      final resolvedPage = meta['pagina'] ?? page;
      final resolvedLimit = meta['limite'] ?? limit;

      final listRaw = data['datos'] ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          data['result'] ??
          meta['data'] ??
          [];

      final citas = (listRaw is List)
          ? listRaw
              .whereType<Map<String, dynamic>>()
              .map(CitaMedica.fromJson)
              .toList()
          : <CitaMedica>[];

      final resolvedTotal =
          total is int ? total : int.tryParse('$total') ?? citas.length;

      return CitasPageResult(
        citas: citas,
        total: resolvedTotal,
        page: resolvedPage is int
            ? resolvedPage
            : int.tryParse('$resolvedPage') ?? page,
        limit: resolvedLimit is int
            ? resolvedLimit
            : int.tryParse('$resolvedLimit') ?? limit,
        message: message,
        status: status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener citas paginadas $e');
      Logger.error('stacktrace $stacktrace');
      return CitasPageResult.empty('No se pudieron cargar las citas');
    }
  }

  Future<ResponseApi> actualizarCita(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch(
      '/citas/$id',
      type: HttpProtocol.patch,
      body: body,
    );
  }

  Future<ResponseApi> actualizarEtiquetas(
    String id,
    List<Map<String, dynamic>> etiquetas,
  ) async {
    return fetch(
      '/citas/$id/etiquetas',
      type: HttpProtocol.patch,
      body: {'etiquetas': etiquetas},
    );
  }

  Future<ResponseApi> actualizarAgrupador(
    String id,
    String? agrupadorId,
  ) async {
    return fetch(
      '/citas/$id/agrupador',
      type: HttpProtocol.patch,
      body: {'agrupadorId': agrupadorId},
    );
  }

  Future<List<EtiquetaCita>> obtenerEtiquetas() async {
    try {
      final response = await fetch('/etiquetas');
      if (response.status != StatusNetwork.connected) {
        return [];
      }
      final raw = response.data['datos'] ??
          response.data['data'] ??
          response.data['list'] ??
          response.data['items'] ??
          [];

      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(EtiquetaCita.fromJson)
            .toList();
      }
    } catch (e, stacktrace) {
      Logger.error('Error al obtener etiquetas $e');
      Logger.error('stacktrace $stacktrace');
    }
    return [];
  }

  Future<List<AgrupadorCita>> obtenerAgrupadores() async {
    try {
      final response = await fetch('/agrupadores');
      if (response.status != StatusNetwork.connected) {
        return [];
      }
      final raw = response.data['datos'] ??
          response.data['data'] ??
          response.data['list'] ??
          response.data['items'] ??
          [];

      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(AgrupadorCita.fromJson)
            .toList();
      }
    } catch (e, stacktrace) {
      Logger.error('Error al obtener agrupadores $e');
      Logger.error('stacktrace $stacktrace');
    }
    return [];
  }
}

class CitasPageResult {
  final List<CitaMedica> citas;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const CitasPageResult({
    required this.citas,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory CitasPageResult.empty(String message) => CitasPageResult(
        citas: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}
