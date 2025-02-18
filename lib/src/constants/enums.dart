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
        return 'Maquinarias';
      case TipoVentas.usuariosDirectos:
        return 'Usuarios directos';
      case TipoVentas.tanqueAdicional:
        return 'Tanque adicional';
    }
  }
}
