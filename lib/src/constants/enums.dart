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

enum TipoMedicion {
  inicialJornada,
  finJornada,
  aSolicitud;

  String get info {
    switch (this) {
      case TipoMedicion.inicialJornada:
        return 'Inicio de jornada';
      case TipoMedicion.finJornada:
        return 'Fin de jornada';
      case TipoMedicion.aSolicitud:
        return 'A solicitud';
    }
  }
}
