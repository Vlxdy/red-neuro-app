import 'package:red_neuro_app/src/models/plan_nutricional.dart';
import 'package:flutter/material.dart';

class PlanNutricionalStore with ChangeNotifier {
  PlanNutricionalStore._();
  static final PlanNutricionalStore instance = PlanNutricionalStore._();

  PlanNutricional? _plan;
  bool _loadingPlan = false;
  bool _savingSeguimiento = false;
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;
  String? _idUsuarioRol;
  bool _planEncontrado = false;
  final Map<String, bool> _seguimiento = {};
  String _comentario = '';

  PlanNutricional? get plan => _plan;
  bool get loadingPlan => _loadingPlan;
  bool get savingSeguimiento => _savingSeguimiento;
  DateTime get selectedDate => _selectedDate;
  String? get errorMessage => _errorMessage;
  String? get idUsuarioRol => _idUsuarioRol;
  bool get planEncontrado => _planEncontrado;
  String get comentario => _comentario;

  List<Map<String, dynamic>> get seguimientoRequest => _seguimiento.entries
      .map((entry) => {
            'idAlimentoPlanNutricional': entry.key,
            'cumplido': entry.value,
          })
      .toList();

  bool estadoAlimento(String idAlimentoPlan) => _seguimiento[idAlimentoPlan] ?? false;

  void setLoadingPlan(bool value) {
    if (_loadingPlan == value) return;
    _loadingPlan = value;
    notifyListeners();
  }

  void setSavingSeguimiento(bool value) {
    if (_savingSeguimiento == value) return;
    _savingSeguimiento = value;
    notifyListeners();
  }

  void setSelectedDate(DateTime value) {
    _selectedDate = value;
    notifyListeners();
  }

  void setError(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  void setIdUsuarioRol(String? value) {
    _idUsuarioRol = value;
    notifyListeners();
  }

  void clearPlan() {
    _plan = null;
    _planEncontrado = false;
    _comentario = '';
    _seguimiento.clear();
    notifyListeners();
  }

  void setPlan(PlanNutricional? plan, {required bool encontrado}) {
    _plan = plan;
    _planEncontrado = encontrado && plan != null;
    _comentario = plan?.seguimiento?.comentario ?? '';
    _seguimiento
      ..clear();
    if (plan != null) {
      final items = plan.seguimiento?.items ?? [];
      for (final alimento in plan.alimentos) {
        final matching = items.firstWhere(
          (element) => element.idAlimentoPlanNutricional == alimento.id,
          orElse: () => PlanSeguimientoItem(
            id: null,
            idAlimentoPlanNutricional: alimento.id,
            cumplido: false,
            fechaRegistro: null,
          ),
        );
        _seguimiento[alimento.id] = matching.cumplido;
      }
    }
    notifyListeners();
  }

  void actualizarSeguimiento(String idAlimentoPlan, bool cumplido) {
    _seguimiento[idAlimentoPlan] = cumplido;
    notifyListeners();
  }

  void actualizarComentario(String comentario) {
    _comentario = comentario;
    notifyListeners();
  }
}
