import 'dart:io';

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class GlobalProvider with ChangeNotifier {
  bool _isMobile = false;
  bool _isTV = false;

  Future<void> loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final model = androidInfo.model.toLowerCase() ?? '';
      final product = androidInfo.product.toLowerCase() ?? '';
      final manufacturer = androidInfo.manufacturer.toLowerCase() ?? '';
      final isTvModel = [
        model,
        product,
        manufacturer,
      ].any((s) =>
          s.contains('mibox') ||
          s.contains('mitv') ||
          s.contains('nexus player') ||
          s.contains('aft') || // Amazon Fire TV
          s.contains('bravia') ||
          s.contains('shield') ||
          s.contains('box') ||
          s.contains('tv'));

      // 优先通过系统特性判断是否为电视（Android TV）
      final features = androidInfo.systemFeatures;

      final isTv = features.contains('android.software.leanback') ||
          features.contains('android.software.leanback_only') ||
          features.contains('android.hardware.type.television') ||
          isTvModel;

      _isTV = isTv;
      if (isTv) {
        _isMobile = false;
      } else {
        // 回退到屏幕尺寸阈值
        final screenSize =
            MediaQueryData.fromView(WidgetsBinding.instance.window).size;
        _isMobile = screenSize.shortestSide < 600;
      }
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _isMobile = iosInfo.name.toLowerCase().contains('iphone');
      _isTV = false; // iOS 不视为 TV
    } else {
      // 其他平台（macOS/Windows/Linux）默认不是 TV，且不是移动端
      _isTV = false;
      _isMobile = false;
    }
    notifyListeners();
  }

  bool get isMobile => _isMobile;
  bool get isTV => _isTV;
}
