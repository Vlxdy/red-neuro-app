import 'package:collection/collection.dart';

class PlanNutricionalResponse {
  PlanNutricionalResponse({required this.encontrado, this.plan});

  final bool encontrado;
  final PlanNutricional? plan;

  factory PlanNutricionalResponse.fromJson(Map<String, dynamic> json) {
    final encontrado = json['encontrado'] == true;
    final planJson = json['planNutricional'] as Map<String, dynamic>?;
    return PlanNutricionalResponse(
      encontrado: encontrado,
      plan: planJson != null ? PlanNutricional.fromJson(planJson) : null,
    );
  }
}

class PlanNutricional {
  PlanNutricional({
    required this.id,
    required this.fecha,
    required this.caloriasObjetivo,
    required this.distribucionMacronutrientes,
    required this.distribucionCalorica,
    required this.esGeneradoAutomatico,
    required this.recomendaciones,
    required this.alimentos,
    this.seguimiento,
  });

  final String id;
  final DateTime fecha;
  final double caloriasObjetivo;
  final MacronutrienteDistribution distribucionMacronutrientes;
  final CaloricDistribution distribucionCalorica;
  final bool esGeneradoAutomatico;
  final String recomendaciones;
  final List<PlanAlimento> alimentos;
  final PlanSeguimiento? seguimiento;

  factory PlanNutricional.fromJson(Map<String, dynamic> json) {
    return PlanNutricional(
      id: (json['id'] ?? '').toString(),
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ?? DateTime.now(),
      caloriasObjetivo: _toDouble(json['caloriasObjetivo']),
      distribucionMacronutrientes:
          MacronutrienteDistribution.fromJson(json['distribucionMacronutrientes'] as Map<String, dynamic>? ?? {}),
      distribucionCalorica:
          CaloricDistribution.fromJson(json['distribucionCalorica'] as Map<String, dynamic>? ?? {}),
      esGeneradoAutomatico: json['esGeneradoAutomatico'] == true,
      recomendaciones: json['recomendaciones']?.toString().trim() ?? '',
      alimentos: ((json['alimentos'] as List<dynamic>?) ?? [])
          .map((e) => PlanAlimento.fromJson(e as Map<String, dynamic>))
          .toList(),
      seguimiento: (json['seguimiento'] as Map<String, dynamic>?) != null
          ? PlanSeguimiento.fromJson(json['seguimiento'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, List<PlanAlimento>> groupAlimentosPorTipo({List<String>? orden}) {
    final grupos = <String, List<PlanAlimento>>{};
    for (final alimento in alimentos) {
      grupos.putIfAbsent(alimento.tipo, () => []).add(alimento);
    }
    if (orden == null) return grupos;
    final sorted = <String, List<PlanAlimento>>{};
    for (final key in orden) {
      if (grupos.containsKey(key)) {
        sorted[key] = grupos[key]!;
      }
    }
    for (final entry in grupos.entries) {
      if (!sorted.containsKey(entry.key)) {
        sorted[entry.key] = entry.value;
      }
    }
    return sorted;
  }
}

class MacronutrienteDistribution {
  MacronutrienteDistribution({required this.objetivo, required this.planGenerado});

  final MacroSummary objetivo;
  final MacroSummary planGenerado;

  factory MacronutrienteDistribution.fromJson(Map<String, dynamic> json) {
    return MacronutrienteDistribution(
      objetivo: MacroSummary.fromJson(json['objetivo'] as Map<String, dynamic>? ?? {}),
      planGenerado: MacroSummary.fromJson(json['planGenerado'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class MacroSummary {
  MacroSummary({
    required this.carbohidratos,
    required this.proteinas,
    required this.grasas,
  });

  final MacroValue carbohidratos;
  final MacroValue proteinas;
  final MacroValue grasas;

  factory MacroSummary.fromJson(Map<String, dynamic> json) {
    return MacroSummary(
      carbohidratos: MacroValue.fromJson(json['carbohidratos'] as Map<String, dynamic>? ?? {}),
      proteinas: MacroValue.fromJson(json['proteinas'] as Map<String, dynamic>? ?? {}),
      grasas: MacroValue.fromJson(json['grasas'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class MacroValue {
  MacroValue({
    required this.gramos,
    required this.calorias,
    required this.porcentaje,
  });

  final double gramos;
  final double calorias;
  final double porcentaje;

  factory MacroValue.fromJson(Map<String, dynamic> json) {
    return MacroValue(
      gramos: _toDouble(json['gramos']),
      calorias: _toDouble(json['calorias']),
      porcentaje: _toDouble(json['porcentaje']),
    );
  }
}

class CaloricDistribution {
  CaloricDistribution({required this.objetivo, required this.planGenerado});

  final List<CaloricEntry> objetivo;
  final List<CaloricEntry> planGenerado;

  factory CaloricDistribution.fromJson(Map<String, dynamic> json) {
    final objetivo = ((json['objetivo'] as List<dynamic>?) ?? [])
        .map((e) => CaloricEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final planGenerado = ((json['planGenerado'] as List<dynamic>?) ?? [])
        .map((e) => CaloricEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return CaloricDistribution(
      objetivo: objetivo,
      planGenerado: planGenerado,
    );
  }

  CaloricEntry? buscarObjetivoPorTipo(String tipo) {
    return objetivo.firstWhereOrNull((element) => element.tipo == tipo);
  }

  CaloricEntry? buscarPlanPorTipo(String tipo) {
    return planGenerado.firstWhereOrNull((element) => element.tipo == tipo);
  }
}

class CaloricEntry {
  CaloricEntry({required this.tipo, required this.calorias, required this.porcentaje});

  final String tipo;
  final double calorias;
  final double porcentaje;

  factory CaloricEntry.fromJson(Map<String, dynamic> json) {
    return CaloricEntry(
      tipo: json['tipo']?.toString() ?? '',
      calorias: _toDouble(json['calorias']),
      porcentaje: _toDouble(json['porcentaje']),
    );
  }
}

class PlanAlimento {
  PlanAlimento({
    required this.id,
    required this.idAlimento,
    required this.nombre,
    required this.categoria,
    required this.unidadMedida,
    required this.cantidadReferencial,
    required this.cantidad,
    required this.tipo,
    required this.calorias,
    required this.carbohidratos,
    required this.proteinas,
    required this.grasa,
    required this.urlImage,
  });

  final String id;
  final String idAlimento;
  final String nombre;
  final String categoria;
  final String unidadMedida;
  final double cantidadReferencial;
  final double cantidad;
  final String tipo;
  final double calorias;
  final double carbohidratos;
  final double proteinas;
  final double grasa;
  final String? urlImage;

  factory PlanAlimento.fromJson(Map<String, dynamic> json) {
    return PlanAlimento(
      id: (json['id'] ?? '').toString(),
      idAlimento: (json['idAlimento'] ?? '').toString(),
      nombre: json['nombre']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      unidadMedida: json['unidadMedida']?.toString() ?? '',
      cantidadReferencial: _toDouble(json['cantidadReferencial']),
      cantidad: _toDouble(json['cantidad']),
      tipo: json['tipo']?.toString() ?? '',
      calorias: _toDouble(json['calorias']),
      carbohidratos: _toDouble(json['carbohidratos']),
      proteinas: _toDouble(json['proteinas']),
      grasa: _toDouble(json['grasa']),
      urlImage: json['urlImage']?.toString(),
    );
  }
}

class PlanSeguimiento {
  PlanSeguimiento({
    required this.id,
    required this.comentario,
    required this.fechaRegistro,
    required this.items,
  });

  final String id;
  final String comentario;
  final DateTime? fechaRegistro;
  final List<PlanSeguimientoItem> items;

  factory PlanSeguimiento.fromJson(Map<String, dynamic> json) {
    return PlanSeguimiento(
      id: (json['id'] ?? '').toString(),
      comentario: json['comentario']?.toString() ?? '',
      fechaRegistro: DateTime.tryParse(json['fechaRegistro']?.toString() ?? ''),
      items: ((json['items'] as List<dynamic>?) ?? [])
          .map((e) => PlanSeguimientoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlanSeguimientoItem {
  PlanSeguimientoItem({
    required this.id,
    required this.idAlimentoPlanNutricional,
    required this.cumplido,
    required this.fechaRegistro,
  });

  final String? id;
  final String idAlimentoPlanNutricional;
  final bool cumplido;
  final DateTime? fechaRegistro;

  factory PlanSeguimientoItem.fromJson(Map<String, dynamic> json) {
    return PlanSeguimientoItem(
      id: json['id']?.toString(),
      idAlimentoPlanNutricional: (json['idAlimentoPlanNutricional'] ?? '').toString(),
      cumplido: json['cumplido'] == true,
      fechaRegistro: DateTime.tryParse(json['fechaRegistro']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'idAlimentoPlanNutricional': idAlimentoPlanNutricional,
      'cumplido': cumplido,
    };
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}
