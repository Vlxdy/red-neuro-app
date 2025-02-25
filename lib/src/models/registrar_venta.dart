class RegistrarVenta {
  List<String> fotos;
  String observacion = '';

  RegistrarVenta(this.fotos, this.observacion);

  static get empty => RegistrarVenta([], '');

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['observacion'] = observacion;

    return data;
  }
}
