import 'package:flutter/material.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 集中构建应用主题，消费 [AppTokens]。
///
/// 现状为单一主题（Material 3，种子色为品牌色）。未来引入暗色模式时，
/// 在此返回 light/dark 两套 ThemeData，并把硬编码颜色逐步迁移到 token。
ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTokens.brand,
      brightness: Brightness.light,
    ),
    // FlutterView 现已全局透明:给 Scaffold 兜一个不透明深色背景,
    // 否则页面会透出窗口后面的黑/花屏。与 bg_wrapper 的黑底一致。
    scaffoldBackgroundColor: Colors.black,
    useMaterial3: true,
  );
}
