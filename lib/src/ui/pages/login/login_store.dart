import 'package:flutter/foundation.dart';
import 'package:control_ventas_movil/src/models/login.dart';

class LoginStore with ChangeNotifier {
  LoginStore._();
  static final instance = LoginStore._();

  Login form = Login.empty();

  String get username => form.username;
  String get password => form.password;

  set username(String value) {
    form.username = value;
    notifyListeners();
  }

  set password(String value) {
    form.password = value;
    notifyListeners();
  }

  void clean() {
    form = Login.empty();
  }
}
