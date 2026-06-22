import 'package:flutter/material.dart';

/// XPlayer Design Token 系统（结构参考 BeeCount 的 BeeTokens / BeeDimens）。
///
/// 设计理念：语义化命名统一管理颜色与尺寸，UI 组件应使用 Token 而非散落的字面量。
/// 现状：单一深色主题（TV / IPTV 场景），**暂未引入暗色模式**，故全部为静态常量，
/// 无需 context，便于在 CustomPainter、默认参数等无 context 处复用。
/// 引入暗色模式时，可改造为 `static Color xxx(BuildContext)` 形式（见 BeeTokens）。
class AppTokens {
  AppTokens._();

  // ========== 品牌色 Brand ==========
  /// 主色种子（#00dc82）。
  static const Color brand = Color(0xFF00DC82);

  // ========== 文字 Text ==========
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Colors.white54;
  static const Color textDisabled = Colors.white38;

  // ========== 图标 Icon ==========
  static const Color iconPrimary = Colors.white;
  static const Color iconSecondary = Colors.white70;

  // ========== 背景 / 表面 Surface ==========
  /// 抽屉、对话框等深色面板背景（rgb 34,34,34）。
  static const Color surfacePanel = Color(0xFF222222);

  /// 频道项缩略图背景（半透明黑 0.35）。
  static const Color surfaceThumb = Color(0x59000000);

  /// 角标 / 标签背景（black54）。
  static const Color surfaceBadge = Colors.black54;

  // ========== 遮罩 Overlay ==========
  /// 背景图之上的统一暗化遮罩（BgWrapper 用）。**单层**，避免叠加过暗。
  static const Color scrim = Color(0x80000000); // black 0.5

  /// 聚焦态播放遮罩（black 0.65）。
  static const Color focusPlayOverlay = Color(0xA6000000);

  // ========== 焦点高亮 Focus（TV 遥控）==========
  /// 默认文字按钮：聚焦态填充（white 0.35）。
  static const Color focusFillDefault = Color(0x59FFFFFF);

  /// 默认文字按钮：非聚焦态填充（white 0.15）。
  static const Color fillDefault = Color(0x26FFFFFF);

  /// 焦点高亮基色。
  static const Color focusRing = brand;

  // ========== 语义色 Semantic ==========
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}

/// 尺寸令牌（间距 / 圆角）。
class AppDimens {
  AppDimens._();

  // 间距
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  // 圆角
  static const double radiusSm = 4;
  static const double radius = 8;
  static const double radiusLg = 12;
  static const double radiusPill = 24;
}

/// 动效时长令牌。
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
}
