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
    useMaterial3: true,
  );
}
