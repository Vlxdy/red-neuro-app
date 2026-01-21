class Recursos {
  static const logoPrincipal = 'assets/imgs/logo_principal.png';
  static const logoPrincipalDark = 'assets/imgs/logo_principal_dark.png';
  static const lock = 'assets/imgs/lock.png';
  static const ubicacion = 'assets/imgs/ubicacion.png';
  static const icono = 'assets/imgs/icono.png';
  static const iconoDark = 'assets/imgs/icono_dark.png';

  static String logoPrincipalFor({required bool isDark}) =>
      isDark ? logoPrincipalDark : logoPrincipal;
  static String iconoFor({required bool isDark}) => isDark ? iconoDark : icono;

  // iconos
  static const iconLock = 'assets/imgs/icono_bloqueado.png';
  static const iconUnlock = 'assets/imgs/icono_desbloqueado.png';
}
