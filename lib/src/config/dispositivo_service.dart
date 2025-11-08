import 'package:alimenta_app/src/config/service_config.dart';
import 'package:alimenta_app/src/constants/keys.dart';
import 'package:alimenta_app/src/constants/network.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:alimenta_app/src/plugins/utils/preferences.dart';
import 'package:alimenta_app/src/plugins/utils/utils.dart';
import 'package:alimenta_app/src/ui/global/alerta_actualizacion.dart';

class ItemVersion {
  int major = 0;
  int minor = 0;
  int patch = 0;
  String? link;
  String? tipoActualizacion;
  ItemVersion(this.major, this.minor, this.patch);

  factory ItemVersion.fromString(String version) {
    final versiones = version.split('.');
    return ItemVersion(
      int.tryParse(versiones[0].toString()) ?? 0,
      int.tryParse(versiones[1].toString()) ?? 0,
      int.tryParse(versiones[2].toString()) ?? 0,
    );
  }

  String? compararVersion(ItemVersion version) {
    if (version.major > major) return 'major';
    if (version.minor > minor) return 'minor';
    if (version.patch > patch) return 'patch';
    return null;
  }

  Map<String, dynamic> toJson() => {
        'major': major,
        'minor': minor,
        'patch': patch,
        'link': link,
        'tipoActualizacion': tipoActualizacion,
      };
}

class DispositivoService extends ServiceConfig {
  DispositivoService(super.urlBase, super.context);
  final _preferences = PreferencesService.instance;
  final _auth = Auth.instance;

  void verificarVersionAsync() async {
    if (context.mounted) {
      final version = await verificarVersion();
      final mostrarDialogo = await _preferences.getBool(Keys.mostrarDialogo);
      if (version != null && mostrarDialogo) {
        DialogService.showAlertDialog('title', 'message', version.link!);
      }
    }
  }

  Future<ItemVersion?> verificarVersion() async {
    try {
      var idUsuario = await _auth.idUsuario;
      if (idUsuario == null) return null;
      final response = await fetch('', type: HttpProtocol.get);
      Logger.success(
          'response -> ${response.log} status -> ${response.status}');
      if (response.status == StatusNetwork.connected) {
        final versionOnline = ItemVersion.fromString(response.data['version']);
        String strVLocal = await Utils.versionAplicacion();
        String? tipoActualizacion =
            ItemVersion.fromString(strVLocal).compararVersion(versionOnline);
        Logger.info('tipo actualizacion: $tipoActualizacion');
        if (tipoActualizacion == null) return null;
        versionOnline.tipoActualizacion = tipoActualizacion;
        versionOnline.link = response.data['link'];
        return versionOnline;
      }
    } catch (error) {
      Logger.error('Error verificando version online: $error');
    }
    return null;
  }
}
