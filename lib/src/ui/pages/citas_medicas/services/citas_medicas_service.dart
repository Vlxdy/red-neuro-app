import 'package:alimenta_app/src/config/service_config.dart';
import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/constants/citas_estado.dart';
import 'package:alimenta_app/src/constants/network.dart';
import 'package:alimenta_app/src/models/cita.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:alimenta_app/src/ui/common/snackbar/snackbar.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/citas_medicas_keys.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/stores/citas_medicas_store.dart';
import 'package:flutter/material.dart';

class CitasMedicasService extends ServiceConfig {
  CitasMedicasService(super.urlBase, super.context);

  final theme = ThemeController.instance;
  final CitasMedicasStore store = CitasMedicasStore.instance;

  Future<String?> _obtenerIdPacienteActual() async {
    try {
      final id = await Auth.instance.idUsuario;
      if (id == null || id.isEmpty) {
        showSnackBar(
          citasMedicasMessenger,
          'No se pudo identificar al paciente autenticado.',
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return null;
      }
      return id;
    } catch (e, stacktrace) {
      Logger.error('Error obteniendo el id del paciente: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'Ocurrió un error al validar la sesión del paciente.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return null;
    }
  }

  Future<void> cargarDatosIniciales() async {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59, 999);

    await obtenerCitasPorRango(
      fechaInicio: inicioMes,
      fechaFin: finMes,
      estados: store.estadosSeleccionados.isEmpty
          ? null
          : store.estadosSeleccionados.toList(),
    );

    await obtenerAgenda(
      pagina: 1,
      limite: store.limite,
      estados: store.estadosSeleccionados.isEmpty
          ? null
          : store.estadosSeleccionados.toList(),
    );
  }

  Future<void> obtenerCitasPorRango({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    List<CitasEstado>? estados,
    String? idPaciente,
    String? idMedico,
  }) async {
    try {
      store.setCargandoCalendario(true);
      final params = <String, String>{
        'fechaInicio': _formatearFecha(fechaInicio, inicio: true),
        'fechaFin': _formatearFecha(fechaFin, inicio: false),
      };

      if (estados != null && estados.isNotEmpty) {
        params['estados'] = estados.map((e) => e.value).join(',');
      }
      if (idPaciente != null && idPaciente.isNotEmpty) {
        params['idPaciente'] = idPaciente;
      }
      if (idMedico != null && idMedico.isNotEmpty) {
        params['idMedico'] = idMedico;
      }

      final response = await fetch(
        '/citas/rango-fechas',
        params: params,
        type: HttpProtocol.get,
      );

      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription(response.message);
      }

      final data = response.data;
      final filas = (data['filas'] as List<dynamic>? ?? [])
          .map((item) => Cita.fromJson(item as Map<String, dynamic>))
          .toList();
      store.setEventosCalendario(filas);
    } catch (e, stacktrace) {
      Logger.error('Error al obtener citas por rango: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'No fue posible cargar el calendario de citas.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      store.setCargandoCalendario(false);
    }
  }

  Future<void> obtenerAgenda({
    int? pagina,
    int? limite,
    String? filtro,
    DateTime? fecha,
    List<CitasEstado>? estados,
    String? idPaciente,
    String? idMedico,
    String? ordenRaw,
  }) async {
    try {
      store.setCargandoAgenda(true);
      final paginaConsulta = pagina ?? store.pagina;
      final limiteConsulta = limite ?? store.limite;
      final params = <String, String>{
        'pagina': paginaConsulta.toString(),
        'limite': limiteConsulta.toString(),
      };
      final filtroLimpio = filtro?.trim();
      if (filtroLimpio != null && filtroLimpio.isNotEmpty) {
        params['filtro'] = filtroLimpio;
      }
      if (fecha != null) {
        params['fecha'] = _formatearFecha(fecha, inicio: true);
      }
      if (estados != null && estados.isNotEmpty) {
        params['estados'] = estados.map((e) => e.value).join(',');
      }
      if (idPaciente != null && idPaciente.isNotEmpty) {
        params['idPaciente'] = idPaciente;
      }
      if (idMedico != null && idMedico.isNotEmpty) {
        params['idMedico'] = idMedico;
      }
      if (ordenRaw != null && ordenRaw.isNotEmpty) {
        params['ordenRaw'] = ordenRaw;
      }

      final response = await fetch(
        '/citas/agenda',
        params: params,
        type: HttpProtocol.get,
      );

      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription(response.message);
      }

      final data = response.data;
      final total = data['total'] is int
          ? data['total'] as int
          : int.tryParse(data['total']?.toString() ?? '0') ?? 0;
      final filas = (data['filas'] as List<dynamic>? ?? [])
          .map((item) => Cita.fromJson(item as Map<String, dynamic>))
          .toList();

      store.setAgenda(
        filas,
        total,
        paginaConsulta,
        limiteConsulta,
        filtroLimpio ?? '',
        fecha,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener agenda de citas: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'No fue posible cargar la agenda de citas.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      store.setCargandoAgenda(false);
    }
  }

  Future<CitaHistorialPage> obtenerHistorial(
    String idCita, {
    int pagina = 1,
    int limite = 10,
  }) async {
    try {
      final params = <String, String>{
        'pagina': pagina.toString(),
        'limite': limite.toString(),
      };

      final response = await fetch(
        '/citas/$idCita/historial',
        params: params,
        type: HttpProtocol.get,
      );

      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription(response.message);
      }

      final data = response.data;
      final total = data['total'] is int
          ? data['total'] as int
          : int.tryParse(data['total']?.toString() ?? '0') ?? 0;
      final filas = (data['filas'] as List<dynamic>? ?? [])
          .map((item) => CitaHistorial.fromJson(item as Map<String, dynamic>))
          .toList();

      return CitaHistorialPage(total: total, registros: filas);
    } catch (e, stacktrace) {
      Logger.error('Error al obtener historial de la cita $idCita: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'No fue posible cargar el historial de la cita.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return CitaHistorialPage(total: 0, registros: []);
    }
  }

  Future<Cita?> obtenerDetalleCita(String idCita) async {
    try {
      final response = await fetch(
        '/citas/$idCita',
        type: HttpProtocol.get,
      );

      if (response.status != StatusNetwork.connected) {
        showSnackBar(
          citasMedicasMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return null;
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      return Cita.fromJson(data);
    } catch (e, stacktrace) {
      Logger.error('Error al obtener detalle de la cita $idCita: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'No fue posible obtener la información actualizada de la cita.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return null;
    }
  }

  Future<bool> crearCitaPaciente({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String detalle,
  }) async {
    final idPaciente = await _obtenerIdPacienteActual();
    if (idPaciente == null) return false;

    try {
      final body = {
        'fechaInicio': fechaInicio.toUtc().toIso8601String(),
        'fechaFin': fechaFin.toUtc().toIso8601String(),
        'detalle': detalle,
      };

      final response = await fetch(
        '/pacientes/$idPaciente/citas',
        type: HttpProtocol.post,
        body: body,
      );

      if (response.status != StatusNetwork.connected) {
        showSnackBar(
          citasMedicasMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return false;
      }

      showSnackBar(
        citasMedicasMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      return true;
    } catch (e, stacktrace) {
      Logger.error('Error al crear cita: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'No fue posible crear la cita médica. Intenta nuevamente.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return false;
    }
  }

  Future<bool> actualizarCitaPaciente({
    required Cita cita,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String detalle,
  }) async {
    final idPaciente = await _obtenerIdPacienteActual();
    if (idPaciente == null) return false;

    try {
      final body = {
        'idPaciente': idPaciente,
        'fechaInicio': fechaInicio.toUtc().toIso8601String(),
        'fechaFin': fechaFin.toUtc().toIso8601String(),
        'detalle': detalle,
        'estado': cita.estado.value,
      };

      final response = await fetch(
        '/citas/${cita.id}',
        type: HttpProtocol.patch,
        body: body,
      );

      if (response.status != StatusNetwork.connected) {
        showSnackBar(
          citasMedicasMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return false;
      }

      showSnackBar(
        citasMedicasMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      return true;
    } catch (e, stacktrace) {
      Logger.error('Error al actualizar cita ${cita.id}: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'No fue posible guardar los cambios de la cita.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return false;
    }
  }

  Future<bool> enviarCita(String idCita) async {
    try {
      final response = await fetch(
        '/citas/$idCita/enviar',
        type: HttpProtocol.post,
        body: const <String, dynamic>{},
      );

      if (response.status != StatusNetwork.connected) {
        showSnackBar(
          citasMedicasMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return false;
      }

      showSnackBar(
        citasMedicasMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      return true;
    } catch (e, stacktrace) {
      Logger.error('Error al enviar cita $idCita a revisión: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'No fue posible enviar la cita a revisión.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return false;
    }
  }

  Future<bool> cancelarCita(String idCita, String motivo) async {
    try {
      final response = await fetch(
        '/citas/$idCita/cancelar',
        type: HttpProtocol.post,
        body: {'motivo': motivo},
      );

      if (response.status != StatusNetwork.connected) {
        showSnackBar(
          citasMedicasMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return false;
      }

      showSnackBar(
        citasMedicasMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      return true;
    } catch (e, stacktrace) {
      Logger.error('Error al cancelar cita $idCita: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'No fue posible cancelar la cita.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return false;
    }
  }

  Future<bool> reabrirCita(String idCita, {String? comentario}) async {
    try {
      final body = comentario != null && comentario.trim().isNotEmpty
          ? {'comentario': comentario.trim()}
          : const <String, dynamic>{};

      final response = await fetch(
        '/citas/$idCita/reabrir',
        type: HttpProtocol.post,
        body: body,
      );

      if (response.status != StatusNetwork.connected) {
        showSnackBar(
          citasMedicasMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return false;
      }

      showSnackBar(
        citasMedicasMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      return true;
    } catch (e, stacktrace) {
      Logger.error('Error al reabrir cita $idCita: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        citasMedicasMessenger,
        'No fue posible volver la cita a borrador.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return false;
    }
  }

  String _formatearFecha(DateTime fecha, {required bool inicio}) {
    final ajustada = inicio
        ? DateTime(fecha.year, fecha.month, fecha.day, 0, 0, 0, 0, 0)
        : DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999, 0);
    return ajustada.toUtc().toIso8601String();
  }
}
