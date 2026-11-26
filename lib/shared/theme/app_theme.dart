import 'package:flutter/material.dart';
import 'package:xplayer/shared/theme/nocturne_theme.dart';
import 'package:xplayer_ui/foundation.dart';

/// 集中构建应用主题，消费 [AppTokens]。
///
/// 现状为单一主题（Material 3，种子色为品牌色）。未来引入暗色模式时，
/// 在此返回 light/dark 两套 ThemeData，并把硬编码颜色逐步迁移到 token。
ThemeData buildAppTheme() {
  final p = appUiPalette();
  final base = XpThemeData(palette: p).materialTheme();
  return base.copyWith(
    primaryColor: p.accent,
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.border),
      ),
      labelStyle: TextStyle(color: p.muted),
    ),
  );
}
