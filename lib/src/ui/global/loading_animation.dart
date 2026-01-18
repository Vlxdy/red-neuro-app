import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class LoadingAnimation with ChangeNotifier {
  LoadingAnimation._();
  static final LoadingAnimation instance = LoadingAnimation._();

  late OverlayState _overlayState;
  OverlayEntry? _overlayEntry;

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set state(OverlayState value) => _overlayState = value;

  void showLoading({String? mensaje}) {
    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        final theme = ThemeController.instance;
        return Container(
          alignment: Alignment.center,
          child: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.white.withValues(alpha: .6),
            ),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(color: theme.warning),
                  if (mensaje != null)
                    Container(
                      margin: const EdgeInsets.only(top: 15),
                      child: Text(
                        mensaje,
                        style: TextStyle(
                          color: theme.fontColor,
                          fontSize: 15,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (_overlayEntry != null) {
      isLoading = true;
      _overlayState.insert(_overlayEntry!);
    }
  }

  void hideLoading() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      isLoading = false;
    }
  }
}
