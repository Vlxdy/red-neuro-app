import 'dart:async';

import 'package:alimenta_app/src/config/service_config.dart';
import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/constants/network.dart';
import 'package:alimenta_app/src/models/plan_nutricional.dart';
import 'package:alimenta_app/src/plugins/utils/debouncer.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:alimenta_app/src/ui/common/snackbar/snackbar.dart';
import 'package:alimenta_app/src/ui/pages/plan_nutricional/stores/plan_nutricional_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final GlobalKey<ScaffoldMessengerState> planNutricionalMessenger =
    GlobalKey<ScaffoldMessengerState>();

class PlanNutricionalService extends ServiceConfig {
  PlanNutricionalService(super.urlBase, super.context);

  final PlanNutricionalStore store = PlanNutricionalStore.instance;
  final Debouncer _debouncer = Debouncer(milliseconds: 600);
  final theme = ThemeController.instance;

  Future<void> initialize() async {
    await _ensurePerfil();
    await cargarPlanParaFecha(store.selectedDate);
  }

  Future<void> _ensurePerfil() async {
    if ((store.idUsuarioRol ?? '').isNotEmpty) return;
    try {
      final response = await fetch('/usuarios/cuenta/perfil');
      if (response.status != StatusNetwork.connected) {
        store.setError(response.message);
        store.clearPlan();
        showSnackBar(
          planNutricionalMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return;
      }
      final data = response.data;
      final roles = ((data['roles'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final pacienteRole = roles.firstWhere(
        (rol) =>
            (rol['rol']?.toString().toUpperCase() == 'PACIENTE') ||
            (rol['nombre']?.toString().toUpperCase() == 'PACIENTE'),
        orElse: () => <String, dynamic>{},
      );
      final idUsuarioRol = pacienteRole['idUsuarioRol']?.toString();
      if (idUsuarioRol == null || idUsuarioRol.isEmpty) {
        store.setError('No se pudo identificar el perfil del paciente.');
        store.clearPlan();
        showSnackBar(
          planNutricionalMessenger,
          'No se pudo identificar el perfil del paciente.',
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return;
      }
      store.setIdUsuarioRol(idUsuarioRol);
    } catch (e, stacktrace) {
      Logger.error('Error obteniendo perfil de usuario: $e');
      Logger.error(stacktrace.toString());
      store.setError('No se pudo obtener la información del perfil.');
    }
  }

  Future<void> cargarPlanParaFecha(DateTime fecha) async {
    await _ensurePerfil();
    final idUsuarioRol = store.idUsuarioRol;
    if (idUsuarioRol == null || idUsuarioRol.isEmpty) {
      store.clearPlan();
      return;
    }
    store.setSelectedDate(fecha);
    store.setLoadingPlan(true);
    store.setError(null);
    try {
      final fechaFormateada = DateFormat('yyyy-MM-dd').format(fecha);
      final response = await fetch(
        '/planes-nutricionales/paciente/$idUsuarioRol/fecha/$fechaFormateada',
      );
      if (response.status != StatusNetwork.connected) {
        store.clearPlan();
        store.setError(response.message);
        showSnackBar(
          planNutricionalMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return;
      }
      final datos = PlanNutricionalResponse.fromJson(response.data);
      store.setPlan(datos.plan, encontrado: datos.encontrado);
      if (!datos.encontrado) {
        store.setError(
            'No se encontró un plan nutricional para la fecha seleccionada.');
      }
    } catch (e, stacktrace) {
      Logger.error('Error al obtener plan nutricional: $e');
      Logger.error(stacktrace.toString());
      store.clearPlan();
      store.setError('Ocurrió un error al obtener el plan nutricional.');
    } finally {
      store.setLoadingPlan(false);
    }
  }

  void actualizarEstadoAlimento(String idAlimentoPlan, bool cumplido) {
    store.actualizarSeguimiento(idAlimentoPlan, cumplido);
    _sincronizarSeguimiento();
  }

  void actualizarComentario(String comentario) {
    store.actualizarComentario(comentario);
    _sincronizarSeguimiento();
  }

  void _sincronizarSeguimiento() {
    final plan = store.plan;
    if (plan == null) return;
    _debouncer.run(() {
      unawaited(_guardarSeguimiento(plan.id));
    });
  }

  Future<void> _guardarSeguimiento(String idPlan) async {
    store.setSavingSeguimiento(true);
    try {
      final body = {
        'comentario': store.comentario,
        'items': store.seguimientoRequest,
      };
      final response = await fetch(
        '/planes-nutricionales/$idPlan/seguimiento',
        type: HttpProtocol.patch,
        body: body,
      );
      if (response.status != StatusNetwork.connected) {
        showSnackBar(
          planNutricionalMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return;
      }
    } catch (e, stacktrace) {
      Logger.error('Error al actualizar seguimiento: $e');
      Logger.error(stacktrace.toString());
      showSnackBar(
        planNutricionalMessenger,
        'No se pudo actualizar el seguimiento. Intenta nuevamente.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      store.setSavingSeguimiento(false);
    }
  }
}
