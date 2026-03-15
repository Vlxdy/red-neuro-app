import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';

class MisCitasHomeService extends ServiceConfig {
  MisCitasHomeService(BuildContext context) : super('', context);

  Future<MisCitasResumenResult> obtenerResumen({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final response = await _fetchWithRetry(
      '/citas/mis-resumen',
      params: {
        if (desde != null) 'desde': desde.toIso8601String(),
        if (hasta != null) 'hasta': hasta.toIso8601String(),
      },
    );

    if (response.status != StatusNetwork.connected) {
      return MisCitasResumenResult.empty(response.message, response.status);
    }

    final data = response.data;
    return MisCitasResumenResult(
      solicitadasPendientesConfirmacion:
          _parseInt(data['solicitadasPendientesConfirmacion']),
      proximasConfirmadas: _parseInt(data['proximasConfirmadas']),
      totalDesdeHoy: _parseInt(data['totalDesdeHoy']),
      primeraFechaConCitas: _parseDate(data['primeraFechaConCitas']),
      status: response.status,
      message: response.message,
    );
  }

  Future<MisCitasSolicitadasResult> obtenerSolicitadas({
    String? cursor,
  }) async {
    final response = await _fetchWithRetry(
      '/citas/mis-solicitadas',
      params: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    if (response.status != StatusNetwork.connected) {
      return MisCitasSolicitadasResult.empty(response.message, response.status);
    }

    final data = response.data;
    final itemsRaw = data['items'];
    final items = (itemsRaw is List)
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(CitaMedica.fromJson)
            .toList()
        : <CitaMedica>[];

    return MisCitasSolicitadasResult(
      items: items,
      nextCursor: data['nextCursor']?.toString(),
      hasMore: data['hasMore'] == true,
      totalAprox: _parseInt(data['totalAprox']),
      status: response.status,
      message: response.message,
    );
  }

  Future<MisCitasTimelineResult> obtenerTimeline({
    String? cursorFechaHora,
    String? cursorId,
  }) async {
    final response = await _fetchWithRetry(
      '/citas/mis-timeline',
      params: {
        if (cursorFechaHora != null && cursorFechaHora.isNotEmpty)
          'cursorFechaHora': cursorFechaHora,
        if (cursorId != null && cursorId.isNotEmpty) 'cursorId': cursorId,
      },
    );

    if (response.status != StatusNetwork.connected) {
      return MisCitasTimelineResult.empty(response.message, response.status);
    }

    final data = response.data;
    final gruposRaw = data['grupos'];
    final grupos = (gruposRaw is List)
        ? gruposRaw
            .whereType<Map<String, dynamic>>()
            .map(MisCitasTimelineGroup.fromJson)
            .toList()
        : <MisCitasTimelineGroup>[];

    final cursorRaw = data['nextCursor'];
    return MisCitasTimelineResult(
      grupos: grupos,
      hasMore: data['hasMore'] == true,
      nextCursorFechaHora: cursorRaw is Map<String, dynamic>
          ? cursorRaw['cursorFechaHora']?.toString()
          : null,
      nextCursorId: cursorRaw is Map<String, dynamic>
          ? cursorRaw['cursorId']?.toString()
          : null,
      status: response.status,
      message: response.message,
    );
  }

  Future<ResponseApi> _fetchWithRetry(
    String path, {
    required Map<String, String> params,
  }) async {
    final response = await fetch(path, params: params);
    if (!_shouldRetry(response.status)) return response;

    await Future<void>.delayed(const Duration(milliseconds: 280));
    return fetch(path, params: params);
  }

  bool _shouldRetry(StatusNetwork status) {
    return status == StatusNetwork.timeout ||
        status == StatusNetwork.noInternet ||
        status == StatusNetwork.exception;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class MisCitasResumenResult {
  final int solicitadasPendientesConfirmacion;
  final int proximasConfirmadas;
  final int totalDesdeHoy;
  final DateTime? primeraFechaConCitas;
  final StatusNetwork status;
  final String message;

  const MisCitasResumenResult({
    required this.solicitadasPendientesConfirmacion,
    required this.proximasConfirmadas,
    required this.totalDesdeHoy,
    required this.primeraFechaConCitas,
    required this.status,
    required this.message,
  });

  factory MisCitasResumenResult.empty(String message, StatusNetwork status) {
    return MisCitasResumenResult(
      solicitadasPendientesConfirmacion: 0,
      proximasConfirmadas: 0,
      totalDesdeHoy: 0,
      primeraFechaConCitas: null,
      status: status,
      message: message,
    );
  }
}

class MisCitasSolicitadasResult {
  final List<CitaMedica> items;
  final String? nextCursor;
  final bool hasMore;
  final int totalAprox;
  final StatusNetwork status;
  final String message;

  const MisCitasSolicitadasResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    required this.totalAprox,
    required this.status,
    required this.message,
  });

  factory MisCitasSolicitadasResult.empty(String message, StatusNetwork status) {
    return MisCitasSolicitadasResult(
      items: const [],
      nextCursor: null,
      hasMore: false,
      totalAprox: 0,
      status: status,
      message: message,
    );
  }
}

class MisCitasTimelineResult {
  final List<MisCitasTimelineGroup> grupos;
  final String? nextCursorFechaHora;
  final String? nextCursorId;
  final bool hasMore;
  final StatusNetwork status;
  final String message;

  const MisCitasTimelineResult({
    required this.grupos,
    required this.nextCursorFechaHora,
    required this.nextCursorId,
    required this.hasMore,
    required this.status,
    required this.message,
  });

  factory MisCitasTimelineResult.empty(String message, StatusNetwork status) {
    return MisCitasTimelineResult(
      grupos: const [],
      nextCursorFechaHora: null,
      nextCursorId: null,
      hasMore: false,
      status: status,
      message: message,
    );
  }
}

class MisCitasTimelineGroup {
  final DateTime? fecha;
  final List<CitaMedica> items;

  const MisCitasTimelineGroup({required this.fecha, required this.items});

  factory MisCitasTimelineGroup.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return MisCitasTimelineGroup(
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      items: (itemsRaw is List)
          ? itemsRaw
                .whereType<Map<String, dynamic>>()
                .map(CitaMedica.fromJson)
                .toList()
          : <CitaMedica>[],
    );
  }
}
