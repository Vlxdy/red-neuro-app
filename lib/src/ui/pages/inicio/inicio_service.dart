import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';

class MisCitasHomeService extends ServiceConfig {
  MisCitasHomeService(BuildContext context) : super('', context);

  Future<HomeBandejaResult> obtenerBandeja({
    String scope = 'mine',
    String? idPersonal,
    String? idLugar,
    DateTime? fechaBase,
    int? limitPreview,
  }) async {
    final response = await _fetchWithRetry(
      '/citas/home/bandeja',
      params: {
        'scope': scope,
        if (idPersonal != null && idPersonal.isNotEmpty) 'idPersonal': idPersonal,
        if (idLugar != null && idLugar.isNotEmpty) 'idLugar': idLugar,
        if (fechaBase != null) 'fechaBase': _formatDate(fechaBase),
        if (limitPreview != null) 'limitPreview': '$limitPreview',
      },
    );

    if (response.status != StatusNetwork.connected) {
      return HomeBandejaResult.empty(response.message, response.status);
    }

    return HomeBandejaResult(
      datos: HomeBandejaData.fromJson(response.data),
      status: response.status,
      message: response.message,
    );
  }

  Future<HomeBandejaListadoResult> obtenerPendientesAprobacion({
    int pagina = 1,
    int limite = 10,
    String scope = 'mine',
    String? idPersonal,
    String? idLugar,
    DateTime? fechaBase,
  }) {
    return _obtenerListado(
      path: '/citas/home/pendientes-aprobacion',
      pagina: pagina,
      limite: limite,
      scope: scope,
      idPersonal: idPersonal,
      idLugar: idLugar,
      fechaBase: fechaBase,
    );
  }

  Future<HomeBandejaListadoResult> obtenerRechazadasSolicitadas({
    int pagina = 1,
    int limite = 10,
    String scope = 'mine',
    String? idPersonal,
    String? idLugar,
    DateTime? fechaBase,
  }) {
    return _obtenerListado(
      path: '/citas/home/rechazadas-solicitadas',
      pagina: pagina,
      limite: limite,
      scope: scope,
      idPersonal: idPersonal,
      idLugar: idLugar,
      fechaBase: fechaBase,
    );
  }

  Future<HomeBandejaListadoResult> obtenerBorradores({
    int pagina = 1,
    int limite = 10,
    String scope = 'mine',
    String? idPersonal,
    String? idLugar,
    DateTime? fechaBase,
  }) {
    return _obtenerListado(
      path: '/citas/home/borradores',
      pagina: pagina,
      limite: limite,
      scope: scope,
      idPersonal: idPersonal,
      idLugar: idLugar,
      fechaBase: fechaBase,
    );
  }

  Future<HomeProgramadasResult> obtenerProgramadasAsignadas({
    int pagina = 1,
    int limite = 10,
    String scope = 'mine',
    String? idPersonal,
    String? idLugar,
    DateTime? fechaBase,
  }) async {
    final response = await _fetchWithRetry(
      '/citas/home/programadas-asignadas',
      params: {
        'pagina': '$pagina',
        'limite': '$limite',
        'scope': scope,
        if (idPersonal != null && idPersonal.isNotEmpty) 'idPersonal': idPersonal,
        if (idLugar != null && idLugar.isNotEmpty) 'idLugar': idLugar,
        if (fechaBase != null) 'fechaBase': _formatDate(fechaBase),
      },
    );

    if (response.status != StatusNetwork.connected) {
      return HomeProgramadasResult.empty(response.message, response.status);
    }

    final filasRaw = response.data['filas'];
    final filas = (filasRaw is List)
        ? filasRaw.whereType<Map<String, dynamic>>().map(HomeGrupoDia.fromJson).toList()
        : <HomeGrupoDia>[];

    return HomeProgramadasResult(
      filas: filas,
      total: _parseInt(response.data['total']),
      status: response.status,
      message: response.message,
    );
  }

  Future<HomeBandejaListadoResult> _obtenerListado({
    required String path,
    required int pagina,
    required int limite,
    required String scope,
    String? idPersonal,
    String? idLugar,
    DateTime? fechaBase,
  }) async {
    final response = await _fetchWithRetry(
      path,
      params: {
        'pagina': '$pagina',
        'limite': '$limite',
        'scope': scope,
        if (idPersonal != null && idPersonal.isNotEmpty) 'idPersonal': idPersonal,
        if (idLugar != null && idLugar.isNotEmpty) 'idLugar': idLugar,
        if (fechaBase != null) 'fechaBase': _formatDate(fechaBase),
      },
    );

    if (response.status != StatusNetwork.connected) {
      return HomeBandejaListadoResult.empty(response.message, response.status);
    }

    final filasRaw = response.data['filas'];
    final filas = (filasRaw is List)
        ? filasRaw.whereType<Map<String, dynamic>>().map(CitaMedica.fromJson).toList()
        : <CitaMedica>[];

    return HomeBandejaListadoResult(
      filas: filas,
      total: _parseInt(response.data['total']),
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

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

class HomeBandejaResult {
  final HomeBandejaData datos;
  final StatusNetwork status;
  final String message;

  const HomeBandejaResult({
    required this.datos,
    required this.status,
    required this.message,
  });

  factory HomeBandejaResult.empty(String message, StatusNetwork status) {
    return HomeBandejaResult(
      datos: HomeBandejaData.empty(),
      status: status,
      message: message,
    );
  }
}

class HomeBandejaData {
  final HomeContadores contadores;
  final HomePreviewBloque pendientesAprobacionAsignadas;
  final HomePreviewBloque rechazadasSolicitadasPorMi;
  final HomePreviewBloque borradores;
  final HomePreviewBloque programadasAsignadas;

  const HomeBandejaData({
    required this.contadores,
    required this.pendientesAprobacionAsignadas,
    required this.rechazadasSolicitadasPorMi,
    required this.borradores,
    required this.programadasAsignadas,
  });

  factory HomeBandejaData.fromJson(Map<String, dynamic> json) {
    final preview = (json['preview'] is Map<String, dynamic>)
        ? json['preview'] as Map<String, dynamic>
        : <String, dynamic>{};

    return HomeBandejaData(
      contadores: HomeContadores.fromJson(json['contadores'] as Map<String, dynamic>? ?? {}),
      pendientesAprobacionAsignadas: HomePreviewBloque.fromJson(
        preview['pendientesAprobacionAsignadas'] as Map<String, dynamic>? ?? {},
      ),
      rechazadasSolicitadasPorMi: HomePreviewBloque.fromJson(
        preview['rechazadasSolicitadasPorMi'] as Map<String, dynamic>? ?? {},
      ),
      borradores: HomePreviewBloque.fromJson(
        preview['borradores'] as Map<String, dynamic>? ?? {},
      ),
      programadasAsignadas: HomePreviewBloque.fromJson(
        preview['programadasAsignadas'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  factory HomeBandejaData.empty() {
    return HomeBandejaData(
      contadores: HomeContadores.empty(),
      pendientesAprobacionAsignadas: HomePreviewBloque.empty(),
      rechazadasSolicitadasPorMi: HomePreviewBloque.empty(),
      borradores: HomePreviewBloque.empty(),
      programadasAsignadas: HomePreviewBloque.empty(),
    );
  }
}

class HomeContadores {
  final int pendientesAprobacionAsignadas;
  final int rechazadasSolicitadasPorMi;
  final int borradores;
  final int programadasAsignadas;

  const HomeContadores({
    required this.pendientesAprobacionAsignadas,
    required this.rechazadasSolicitadasPorMi,
    required this.borradores,
    required this.programadasAsignadas,
  });

  factory HomeContadores.fromJson(Map<String, dynamic> json) {
    int parse(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    return HomeContadores(
      pendientesAprobacionAsignadas: parse(json['pendientesAprobacionAsignadas']),
      rechazadasSolicitadasPorMi: parse(json['rechazadasSolicitadasPorMi']),
      borradores: parse(json['borradores']),
      programadasAsignadas: parse(json['programadasAsignadas']),
    );
  }

  factory HomeContadores.empty() {
    return const HomeContadores(
      pendientesAprobacionAsignadas: 0,
      rechazadasSolicitadasPorMi: 0,
      borradores: 0,
      programadasAsignadas: 0,
    );
  }
}

class HomePreviewBloque {
  final List<CitaMedica> items;
  final int total;
  final int limitAplicado;
  final bool hasMore;

  const HomePreviewBloque({
    required this.items,
    required this.total,
    required this.limitAplicado,
    required this.hasMore,
  });

  factory HomePreviewBloque.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return HomePreviewBloque(
      items: (itemsRaw is List)
          ? itemsRaw.whereType<Map<String, dynamic>>().map(CitaMedica.fromJson).toList()
          : <CitaMedica>[],
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      limitAplicado: int.tryParse(json['limitAplicado']?.toString() ?? '') ?? 0,
      hasMore: json['hasMore'] == true,
    );
  }

  factory HomePreviewBloque.empty() {
    return const HomePreviewBloque(items: [], total: 0, limitAplicado: 0, hasMore: false);
  }
}

class HomeBandejaListadoResult {
  final List<CitaMedica> filas;
  final int total;
  final StatusNetwork status;
  final String message;

  const HomeBandejaListadoResult({
    required this.filas,
    required this.total,
    required this.status,
    required this.message,
  });

  factory HomeBandejaListadoResult.empty(String message, StatusNetwork status) {
    return HomeBandejaListadoResult(
      filas: const [],
      total: 0,
      status: status,
      message: message,
    );
  }
}

class HomeProgramadasResult {
  final List<HomeGrupoDia> filas;
  final int total;
  final StatusNetwork status;
  final String message;

  const HomeProgramadasResult({
    required this.filas,
    required this.total,
    required this.status,
    required this.message,
  });

  factory HomeProgramadasResult.empty(String message, StatusNetwork status) {
    return HomeProgramadasResult(
      filas: const [],
      total: 0,
      status: status,
      message: message,
    );
  }
}

class HomeGrupoDia {
  final String dia;
  final List<CitaMedica> items;

  const HomeGrupoDia({required this.dia, required this.items});

  factory HomeGrupoDia.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return HomeGrupoDia(
      dia: json['dia']?.toString() ?? '',
      items: (itemsRaw is List)
          ? itemsRaw.whereType<Map<String, dynamic>>().map(CitaMedica.fromJson).toList()
          : <CitaMedica>[],
    );
  }
}
