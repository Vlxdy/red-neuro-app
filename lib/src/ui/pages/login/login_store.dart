import 'package:flutter/foundation.dart';
import 'package:red_neuro_app/src/models/login.dart';

enum LoginFeedbackType { error, info }

class LoginStore with ChangeNotifier {
  LoginStore._();
  static final LoginStore instance = LoginStore._();

  Login form = Login.empty();
  String? _feedbackMessage;
  LoginFeedbackType? _feedbackType;

  String get username => form.username;
  String get password => form.password;
  String? get feedbackMessage => _feedbackMessage;
  LoginFeedbackType? get feedbackType => _feedbackType;
  bool get hasFeedback =>
      _feedbackMessage != null && _feedbackMessage!.trim().isNotEmpty;

  set username(String value) {
    form.username = value;
    notifyListeners();
  }

  set password(String value) {
    form.password = value;
    notifyListeners();
  }

  void setFeedback(
    String message, {
    LoginFeedbackType type = LoginFeedbackType.error,
  }) {
    _feedbackMessage = message;
    _feedbackType = type;
    notifyListeners();
  }

  void clearFeedback({bool notify = true}) {
    _feedbackMessage = null;
    _feedbackType = null;
    if (notify) {
      notifyListeners();
    }
  }

  void clean() {
    form = Login.empty();
    clearFeedback(notify: false);
    notifyListeners();
  }
}
