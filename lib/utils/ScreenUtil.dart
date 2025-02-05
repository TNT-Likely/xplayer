import 'package:flutter/widgets.dart';

class ScreenUtil {
  static double getScreenWidth({required BuildContext context}) {
    var size = MediaQuery.of(context).size;

    print("width------>${size.width}");
    return size.width;
  }

  static double getScreenHeight({required BuildContext context}) {
    var size = MediaQuery.of(context).size;

    return size.height;
  }
}
