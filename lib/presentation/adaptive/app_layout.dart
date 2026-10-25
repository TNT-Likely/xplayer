import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xplayer_ui/foundation.dart';

/// 窗口布局与输入方式独立：窄桌面仍使用鼠标，宽手机仍支持触摸。
@immutable
class AppLayout {
  const AppLayout({
    required this.width,
    required this.isTv,
    required this.platform,
  });
  final double width;
  final bool isTv;
  final TargetPlatform platform;
  bool get compact => !isTv && width < 600;
  bool get expandedNavigation => width >= 1200 || (isTv && width >= 1000);
  bool get useBottomNavigation => compact;
  double get navigationWidth => expandedNavigation ? (isTv ? 240 : 224) : 88;
  double get padding => isTv
      ? 40
      : compact
      ? 18
      : 28;
  XpDevice get device => isTv ? XpDevice.tv : XpThemeData.deviceForWidth(width);
  XpInputMode get input => isTv
      ? XpInputMode.directional
      : switch (platform) {
          TargetPlatform.android || TargetPlatform.iOS => XpInputMode.touch,
          _ => XpInputMode.pointer,
        };

  int channelColumns(double availableWidth, {int sizeLevel = 2}) {
    final minimum = isTv ? 330.0 : 260.0 + (2 - sizeLevel) * 35;
    return ((availableWidth + 16) / (minimum + 16)).floor().clamp(
      1,
      isTv ? 4 : 6,
    );
  }
}
