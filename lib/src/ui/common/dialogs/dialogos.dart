import 'dart:io';

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class Dialogo {
  static Future showNativeModalBottomSheet(
      {required BuildContext context,
      required Widget widget,
      bool dragable = false,
      isDismissible = true}) async {
    // double screenHeight = View.of(context).physicalSize.height /
    //     View.of(context).devicePixelRatio;
    // double screenHeight =
    //     ui.window.physicalSize.height / ui.window.devicePixelRatio;
    return Platform.isIOS
        ? await showCupertinoModalBottomSheet(
            expand: true,
            enableDrag: dragable,
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => PopScope(
              canPop: isDismissible,
              child: widget,
            ),
            isDismissible: isDismissible,
          )
        : await showMaterialModalBottomSheet(
            expand: true,
            enableDrag: dragable,
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                PopScope(canPop: isDismissible, child: widget),
            isDismissible: isDismissible,
          );
  }
}
