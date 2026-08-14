import 'package:flutter/material.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 集中构建应用主题，消费 [AppTokens]。
///
/// 深浅两套由 [buildAppTheme] 按 [Brightness] 产出，MaterialApp 同时挂
/// `theme` / `darkTheme`，再用 `themeMode` 选择。
///
/// ⚠️ 注意 [AppTokens] 的取值不依赖 ThemeData——它由全局 notifier 驱动。
/// 这里构建 ThemeData 主要是为了 Material 组件（Switch、Dialog、Ripple 等）
/// 的默认外观跟着一起变，两套机制并行但不冲突。
ThemeData buildAppTheme({Brightness brightness = Brightness.dark}) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTokens.brand,
      brightness: brightness,
    ),
    // FlutterView 现已全局透明:给 Scaffold 兜一个不透明背景,
    // 否则页面会透出窗口后面的黑/花屏。
    scaffoldBackgroundColor: isDark ? Colors.black : const Color(0xFFF4F7F9),
    useMaterial3: true,
  );
}
