import 'package:flutter/material.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 主题强调色的预设色板。
///
/// 选色标准:对 [AppTokens.surfacePanel] (#222222,抽屉/弹窗背景,也是主色
/// 出现最多的场合)的 WCAG 对比度 ≥ 3:1 —— WCAG 2.1 对非文本 UI 组件的
/// 最低要求。主色驱动 TV 焦点环,对比度不足会让焦点发闷。
///
/// 新增颜色必须:(1) 同时加入下方 [all] 列表,否则 UI 遍历不到;
/// (2) 先过 test/theme/app_palette_test.dart 的对比度与不透明断言。
/// 设计阶段已因此排除紫 #9C27B0(对比度仅 2.52),改用 #BA68C8(4.47)。
///
/// 注意 `] (` 之间的空格是必需的:去掉就变成 markdown 链接语法,
/// dartdoc 引用会失效,IDE 悬浮提示里会渲染成一个指向乱码 URL 的链接。
class AppPalette {
  AppPalette._();

  /// 默认色,即改造前硬编码的品牌色。
  static const Color green = Color(0xFF00DC82); // 对比度 8.76
  static const Color blue = Color(0xFF2196F3); // 5.09
  static const Color cyan = Color(0xFF00BCD4); // 6.93
  static const Color purple = Color(0xFFBA68C8); // 4.47
  static const Color pink = Color(0xFFE91E63); // 3.66
  static const Color red = Color(0xFFF44336); // 4.32
  static const Color orange = Color(0xFFFF9800); // 7.38
  static const Color amber = Color(0xFFFFC107); // 9.76

  /// 色块上的前景色(选中对勾)。
  ///
  /// 用黑而非白:色板的选色标准要求每个色对深色面板 ≥3:1,这使它们全都是亮色
  /// (亮度 ≥0.192),而白/黑等对比的临界亮度是 0.179 —— 故黑色标记在 8 色上
  /// 一律更清晰。实测白色最差仅 1.63(amber),黑色最差 4.84(pink)。
  static const Color onPalette = Colors.black;

  /// 色板顺序。UI 遍历此列表,避免各处重复维护顺序。
  static const List<Color> all = <Color>[
    green,
    blue,
    cyan,
    purple,
    pink,
    red,
    orange,
    amber,
  ];
}
