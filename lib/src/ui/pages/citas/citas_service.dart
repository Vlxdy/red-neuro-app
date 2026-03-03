import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/models/estudio.dart';
import 'package:red_neuro_app/src/models/historial_cita.dart';
import 'package:red_neuro_app/src/models/paciente.dart';
import 'package:red_neuro_app/src/models/personal_medico.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';

class CitasService extends ServiceConfig {
  CitasService(BuildContext context) : super('', context);

  Future<Map<DateTime, int>> obtenerCantidadCitasPorDia({
    required Map<String, String> filtros,
  }) async {
    try {
      final response = await fetch('/citas/cantidad-por-dia', params: filtros);
      if (!context.mounted) return {};

      if (response.status != StatusNetwork.connected) {
        if (response.status != StatusNetwork.noContent) {
          final message = response.message.isNotEmpty
              ? response.message
              : 'No se pudo cargar la cantidad de citas por día.';
          await showErrorDialog(context, message);
        }
        return {};
      }

      final raw =
          response.data['datos'] ??
          response.data['data'] ??
          response.data['list'] ??
          response.data['items'] ??
          [];

      if (raw is! List) return {};

      final result = <DateTime, int>{};
      for (final item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final fechaRaw = (item['fecha'] ?? '').toString().trim();
        if (fechaRaw.isEmpty) continue;

        // Normaliza por componente calendario (YYYY-MM-DD) para evitar
        // desfases por zona horaria en vista semanal/mensual.
        final fechaBase = fechaRaw.length >= 10
            ? fechaRaw.substring(0, 10)
            : fechaRaw;
        final partes = fechaBase.split('-');
        if (partes.length != 3) continue;
        final year = int.tryParse(partes[0]);
        final month = int.tryParse(partes[1]);
        final day = int.tryParse(partes[2]);
        if (year == null || month == null || day == null) continue;
        final key = DateTime(year, month, day);
        final cantidadRaw = item['cantidad'];
        final cantidad = cantidadRaw is int
            ? cantidadRaw
            : int.tryParse('$cantidadRaw') ?? 0;
        result[key] = cantidad;
      }

      return result;
    } catch (e, stacktrace) {
      Logger.error('Error al obtener cantidad de citas por día $e');
      Logger.error('stacktrace $stacktrace');
      await showErrorDialog(
        context,
        'No se pudo cargar la cantidad de citas por día.',
      );
      return {};
    }
  }

  Future<List<CitaMedica>> obtenerCitas({
    bool soloMisCitas = false,
    Map<String, String>? filtros,
  }) async {
    try {
      final response = await fetch(
        soloMisCitas ? '/citas/mis-citas' : '/citas',
        params: filtros,
      );
      if (!context.mounted) return [];

      if (response.status != StatusNetwork.connected) {
        if (response.status != StatusNetwork.noContent) {
          final message = response.message.isNotEmpty
              ? response.message
              : 'No se pudieron cargar las citas.';
          await showErrorDialog(context, message);
        }
        return [];
      }

      final raw =
          response.data['datos'] ??
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
      await showErrorDialog(context, 'No se pudieron cargar las citas.');
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

      final response = await fetch('/citas/paginado', params: params);

      if (!context.mounted) {
        return CitasPageResult.empty('Operación cancelada');
      }

      if (response.status != StatusNetwork.connected) {
        final message = response.message.isNotEmpty
            ? response.message
            : 'No se pudieron cargar las citas paginadas.';
        if (response.status != StatusNetwork.noContent) {
          await showErrorDialog(context, message);
        }
        return CitasPageResult.empty(message);
      }

      final status = response.status;
      final message = response.message;

      final data = response.data;
      final meta = data['meta'] ?? data['paginacion'] ?? {};
      final total =
          meta['totalRegistros'] ?? meta['total'] ?? data['total'] ?? 0;
      final resolvedPage = meta['pagina'] ?? page;
      final resolvedLimit = meta['limite'] ?? limit;

      final listRaw =
          data['datos'] ??
          data['filas'] ??
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

      final resolvedTotal = total is int
          ? total
          : int.tryParse('$total') ?? citas.length;

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
      await showErrorDialog(
        context,
        'No se pudieron cargar las citas paginadas.',
      );
      return CitasPageResult.empty('No se pudieron cargar las citas');
    }
  }

  Future<HistorialCitasPageResult> obtenerHistorialCita({
    required String id,
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
      final response = await fetch('/citas/$id/historial', params: params);

      if (!context.mounted) {
        return HistorialCitasPageResult.empty('Operación cancelada');
      }

      if (response.status != StatusNetwork.connected) {
        final message = response.message.isNotEmpty
            ? response.message
            : 'No se pudo cargar el historial.';
        if (response.status != StatusNetwork.noContent) {
          await showErrorDialog(context, message);
        }
        return HistorialCitasPageResult.empty(message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = datos['total'] ?? data['total'] ?? 0;
      final filasRaw = datos['filas'] ?? data['filas'] ?? data['datos'] ?? [];
      final historial = (filasRaw is List)
          ? filasRaw
                .whereType<Map<String, dynamic>>()
                .map(HistorialCita.fromJson)
                .toList()
          : <HistorialCita>[];

      final total = totalRaw is int
          ? totalRaw
          : int.tryParse('$totalRaw') ?? historial.length;

      return HistorialCitasPageResult(
        historial: historial,
        total: total,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener historial $e');
      Logger.error('stacktrace $stacktrace');
      if (context.mounted) {
        await showErrorDialog(context, 'No se pudo cargar el historial.');
      }
      return HistorialCitasPageResult.empty('No se pudo cargar el historial.');
    }
  }

  Future<ResponseApi> actualizarCita(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch('/citas/$id', type: HttpProtocol.patch, body: body);
  }

  Future<ResponseApi> editarBorradorCita(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch('/citas/$id/editar-borrador', type: HttpProtocol.patch, body: body);
  }

  Future<ResponseApi> ajustarSolicitadaCita(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch('/citas/$id/ajustar-solicitada', type: HttpProtocol.patch, body: body);
  }

  Future<ResponseApi> enviarCita(
    String id, {
    String? idMedico,
  }) async {
    final body = <String, dynamic>{
      if (idMedico != null && idMedico.trim().isNotEmpty)
        'idMedico': idMedico.trim(),
    };
    return fetch('/citas/$id/enviar', type: HttpProtocol.post, body: body);
  }

  Future<ResponseApi> confirmarCita(
    String id, {
    Map<String, dynamic>? body,
  }) async {
    return fetch(
      '/citas/$id/confirmar',
      type: HttpProtocol.post,
      body: body ?? const {},
    );
  }

  Future<ResponseApi> rechazarCita(String id, {String? motivoRechazo}) async {
    final body = <String, dynamic>{
      if (motivoRechazo != null && motivoRechazo.trim().isNotEmpty)
        'motivoRechazo': motivoRechazo.trim(),
    };
    return fetch('/citas/$id/rechazar', type: HttpProtocol.post, body: body);
  }

  Future<ResponseApi> cancelarCita(String id) async {
    return fetch('/citas/$id/cancelar', type: HttpProtocol.post, body: const {});
  }

  Future<ResponseApi> completarCita(String id) async {
    return fetch('/citas/$id/completar', type: HttpProtocol.post, body: const {});
  }

  Future<ResponseApi> marcarNoAsistioCita(String id) async {
    return fetch(
      '/citas/$id/estado',
      type: HttpProtocol.patch,
      body: const {'estado': 'NO_ASISTIO'},
    );
  }

  Future<ResponseApi> reprogramarCita(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch('/citas/$id/reprogramar', type: HttpProtocol.patch, body: body);
  }

  Future<ResponseApi> eliminarCitaBorrador(String id) async {
    return fetch('/citas/$id', type: HttpProtocol.delete);
  }

  Future<ResponseApi> crearCita(Map<String, dynamic> body) async {
    return fetch('/citas', type: HttpProtocol.post, body: body);
  }

  Future<CatalogoPageResult<Especialidad>> obtenerEspecialidades({
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final params = <String, String>{
        'pagina': '$page',
        'limite': '$limit',
        if (filtro != null && filtro.trim().isNotEmpty) 'filtro': filtro.trim(),
      };
      final response = await fetch('/especialidades', params: params);
      if (response.status != StatusNetwork.connected) {
        return CatalogoPageResult.empty(
          response.message.isNotEmpty
              ? response.message
              : 'No se pudieron cargar las especialidades.',
        );
      }
      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = datos['total'] ?? data['total'] ?? 0;
      final filasRaw =
          datos['filas'] ??
          datos['items'] ??
          data['filas'] ??
          data['items'] ??
          data['datos'] ??
          [];
      final especialidades = (filasRaw is List)
          ? filasRaw
                .whereType<Map<String, dynamic>>()
                .map(Especialidad.fromJson)
                .toList()
          : <Especialidad>[];
      final total = totalRaw is int
          ? totalRaw
          : int.tryParse('$totalRaw') ?? especialidades.length;
      return CatalogoPageResult(
        items: especialidades,
        total: total,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener especialidades $e');
      Logger.error('stacktrace $stacktrace');
      return CatalogoPageResult.empty(
        'No se pudieron cargar las especialidades.',
      );
    }
  }

  Future<CatalogoPageResult<Servicio>> obtenerServiciosPorEspecialidad({
    required String especialidadId,
    required String tipo,
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final params = <String, String>{
        'pagina': '$page',
        'limite': '$limit',
        'tipo': tipo,
        if (filtro != null && filtro.trim().isNotEmpty) 'filtro': filtro.trim(),
      };
      final response = await fetch(
        '/servicios/especialidades/$especialidadId',
        params: params,
      );
      if (response.status != StatusNetwork.connected) {
        return CatalogoPageResult.empty(
          response.message.isNotEmpty
              ? response.message
              : 'No se pudieron cargar los servicios.',
        );
      }
      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = datos['total'] ?? data['total'] ?? 0;
      final filasRaw =
          datos['filas'] ??
          datos['items'] ??
          data['filas'] ??
          data['items'] ??
          data['datos'] ??
          [];
      final servicios = (filasRaw is List)
          ? filasRaw
                .whereType<Map<String, dynamic>>()
                .map(Servicio.fromJson)
                .toList()
          : <Servicio>[];
      final total = totalRaw is int
          ? totalRaw
          : int.tryParse('$totalRaw') ?? servicios.length;
      return CatalogoPageResult(
        items: servicios,
        total: total,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener servicios por especialidad $e');
      Logger.error('stacktrace $stacktrace');
      return CatalogoPageResult.empty('No se pudieron cargar los servicios.');
    }
  }

  @Deprecated('Usar obtenerServiciosPorEspecialidad')
  Future<CatalogoPageResult<Servicio>> obtenerEstudiosPorEspecialidad({
    required String especialidadId,
    required String tipo,
    int page = 1,
    int limit = 10,
    String? filtro,
  }) => obtenerServiciosPorEspecialidad(
        especialidadId: especialidadId,
        tipo: tipo,
        page: page,
        limit: limit,
        filtro: filtro,
      );

  Future<CatalogoPageResult<Servicio>> obtenerServicios({
    required String tipo,
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final params = <String, String>{
        'pagina': '$page',
        'limite': '$limit',
        'tipo': tipo,
        if (filtro != null && filtro.trim().isNotEmpty) 'filtro': filtro.trim(),
      };
      final response = await fetch(
        '/servicios',
        params: params,
      );
      if (response.status != StatusNetwork.connected) {
        return CatalogoPageResult.empty(
          response.message.isNotEmpty
              ? response.message
              : 'No se pudieron cargar los servicios.',
        );
      }
      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = datos['total'] ?? data['total'] ?? 0;
      final filasRaw =
          datos['filas'] ??
          datos['items'] ??
          data['filas'] ??
          data['items'] ??
          data['datos'] ??
          [];
      final servicios = (filasRaw is List)
          ? filasRaw
                .whereType<Map<String, dynamic>>()
                .map(Servicio.fromJson)
                .toList()
          : <Servicio>[];
      final total = totalRaw is int
          ? totalRaw
          : int.tryParse('$totalRaw') ?? servicios.length;
      return CatalogoPageResult(
        items: servicios,
        total: total,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener servicios $e');
      Logger.error('stacktrace $stacktrace');
      return CatalogoPageResult.empty('No se pudieron cargar los servicios.');
    }
  }

  Future<CatalogoPageResult<Paciente>> obtenerPacientes({
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final params = <String, String>{
        'pagina': '$page',
        'limite': '$limit',
        if (filtro != null && filtro.trim().isNotEmpty) 'filtro': filtro.trim(),
      };
      final response = await fetch('/pacientes', params: params);
      if (response.status != StatusNetwork.connected) {
        return CatalogoPageResult.empty(
          response.message.isNotEmpty
              ? response.message
              : 'No se pudieron cargar los pacientes.',
        );
      }
      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = datos['total'] ?? data['total'] ?? 0;
      final filasRaw =
          datos['filas'] ??
          datos['items'] ??
          data['filas'] ??
          data['items'] ??
          data['datos'] ??
          [];
      final pacientes = (filasRaw is List)
          ? filasRaw
                .whereType<Map<String, dynamic>>()
                .map(Paciente.fromJson)
                .toList()
          : <Paciente>[];
      final total = totalRaw is int
          ? totalRaw
          : int.tryParse('$totalRaw') ?? pacientes.length;
      return CatalogoPageResult(
        items: pacientes,
        total: total,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener pacientes $e');
      Logger.error('stacktrace $stacktrace');
      return CatalogoPageResult.empty('No se pudieron cargar los pacientes.');
    }
  }

  Future<CatalogoPageResult<PersonalMedico>> obtenerPersonalMedico({
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final params = <String, String>{
        'pagina': '$page',
        'limite': '$limit',
        if (filtro != null && filtro.trim().isNotEmpty) 'filtro': filtro.trim(),
      };
      final response = await fetch('/personal-salud', params: params);
      if (response.status != StatusNetwork.connected) {
        return CatalogoPageResult.empty(
          response.message.isNotEmpty
              ? response.message
              : 'No se pudo cargar el personal médico.',
        );
      }
      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = datos['total'] ?? data['total'] ?? 0;
      final filasRaw =
          datos['filas'] ??
          datos['items'] ??
          data['filas'] ??
          data['items'] ??
          data['datos'] ??
          [];
      final medicos = (filasRaw is List)
          ? filasRaw
                .whereType<Map<String, dynamic>>()
                .map(PersonalMedico.fromJson)
                .toList()
          : <PersonalMedico>[];
      final total = totalRaw is int
          ? totalRaw
          : int.tryParse('$totalRaw') ?? medicos.length;
      return CatalogoPageResult(
        items: medicos,
        total: total,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener personal medico $e');
      Logger.error('stacktrace $stacktrace');
      return CatalogoPageResult.empty('No se pudo cargar el personal médico.');
    }
  }

  Future<ResponseApi> crearPaciente(Map<String, dynamic> body) async {
    return fetch('/pacientes', type: HttpProtocol.post, body: body);
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

class HistorialCitasPageResult {
  final List<HistorialCita> historial;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  HistorialCitasPageResult({
    required this.historial,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory HistorialCitasPageResult.empty([String message = '']) {
    return HistorialCitasPageResult(
      historial: const [],
      total: 0,
      page: 1,
      limit: 10,
      message: message,
      status: StatusNetwork.noContent,
    );
  }
}

class CatalogoPageResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const CatalogoPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory CatalogoPageResult.empty(String message) => CatalogoPageResult(
    items: const [],
    total: 0,
    page: 1,
    limit: 10,
    message: message,
    status: StatusNetwork.noContent,
  );
}
