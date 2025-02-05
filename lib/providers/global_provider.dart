import 'dart:io';

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class GlobalProvider with ChangeNotifier {
  BaseDeviceInfo? _info;

  bool _isMobile = false;

  Future<void> loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _info = androidInfo;
      // 使用屏幕尺寸来判断是否为手机
      final screenSize =
          MediaQueryData.fromView(WidgetsBinding.instance.window).size;
      _isMobile = screenSize.shortestSide < 600; // 可以根据需要调整这个阈值
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _info = iosInfo;
      _isMobile = iosInfo.name.toLowerCase().contains('iphone');
    }
    notifyListeners();
  }

  bool get isMobile => _isMobile;
}
