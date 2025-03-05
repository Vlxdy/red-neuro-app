enum TipoVentas {
  bidones,
  maquinarias,
  usuariosDirectos,
  tanqueAdicional;

  String get descripcion {
    switch (this) {
      case TipoVentas.bidones:
        return 'Bidones';
      case TipoVentas.maquinarias:
        return 'Maquinaria';
      case TipoVentas.usuariosDirectos:
        return 'Usuario directo';
      case TipoVentas.tanqueAdicional:
        return 'Tanque adicional';
    }
  }
}
