import 'package:flutter/widgets.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';

class AuthService extends ServiceConfig {
  AuthService(BuildContext context) : super('', context);

  Future<ResponseApi> cambiarRol(String idRol) {
    return fetch(
      '/cambiarRol',
      type: HttpProtocol.patch,
      body: {'idRol': idRol},
    );
  }
}
