import 'package:flutter/material.dart';
import 'package:xplayer/shared/theme/theme_mode_setting.dart';
import 'package:xplayer/shared/theme/theme_settings.dart';

/// XPlayer Design Token 系统（结构参考 BeeCount 的 BeeTokens / BeeDimens）。
///
/// 设计理念：语义化命名统一管理颜色与尺寸，UI 组件应使用 Token 而非散落的字面量。
///
/// **取值方式**：颜色是静态 getter，由 [appThemeMode] / [themeColor] 两个全局
/// notifier 驱动，MaterialApp 监听它们重建。因此调用点**不需要** context，
/// 在 CustomPainter、默认参数等无 context 处照样能用。
///
/// 曾评估过改成 `static Color xxx(BuildContext)`（BeeTokens 那种形态），
/// 结论是不必：实测全仓只有 17 处把 token 用在 `const` 上下文里，
/// 去掉那几个 `const` 比让每个调用点都拿 context 便宜得多。
///
/// 配色取向：中性色一律带轻微冷偏（蓝向）。纯中性灰读起来像没选过色，
/// 冷偏则读起来是有意为之，也与视频内容的冷调更协调。
class AppTokens {
  AppTokens._();

  // ========== 品牌色 Brand ==========
  /// 主色种子。由用户在「界面 → 主题色」中设定，默认 #00DC82。
  static Color get brand => themeColor.value;

  // ========== 双色板 ==========
  //
  // 深色是主场景（视频应用），浅色是可选项。两套同名不同值，
  // 由 [isDarkMode] 在取值时选择 —— 沿用 [brand] 那套「可变静态 getter +
  // ValueNotifier 驱动 MaterialApp 重建」的机制，因此调用点无需改成
  // `Color xxx(BuildContext)`，在无 context 处也照样能用。

  static const _AppPaletteSet _dark = _AppPaletteSet(
    textPrimary: Color(0xFFE9EEF4),
    textSecondary: Color(0xFF94A2B1),
    textTertiary: Color(0xFF7A8896),
    textDisabled: Color(0xFF46525E),
    surfaceGround: Color(0xFF0A0E13),
    surfaceDefault: Color(0xFF131A22),
    surfaceRaised: Color(0xFF1D2731),
    surfacePlate: Color(0xFF252F3A),
    line: Color(0xFF33404D),
  );

  static const _AppPaletteSet _light = _AppPaletteSet(
    textPrimary: Color(0xFF0F1620),
    textSecondary: Color(0xFF56646F),
    textTertiary: Color(0xFF6E7C88),
    textDisabled: Color(0xFFA8B2BC),
    surfaceGround: Color(0xFFF4F7F9),
    surfaceDefault: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfacePlate: Color(0xFFEDF1F5),
    line: Color(0xFFD5DDE4),
  );

  static _AppPaletteSet get _p => isDarkMode ? _dark : _light;

  // ========== 文字 Text ==========
  /// 正文。深色下是冷偏近白而非纯白——纯白在深色底上偏「刺」。
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;

  /// 等宽副行（分组、地区、时间码）这类次级信息。
  static Color get textTertiary => _p.textTertiary;
  static Color get textDisabled => _p.textDisabled;

  // ========== 图标 Icon ==========
  static Color get iconPrimary => _p.textPrimary;
  static Color get iconSecondary => _p.textSecondary;

  // ========== 背景 / 表面 Surface ==========
  //
  // 四级阶梯，越靠上越「浮起」。深色下全部带冷偏（蓝向）——
  // 纯中性灰读起来像没选过色。

  /// 页面底色。
  static Color get surfaceGround => _p.surfaceGround;

  /// 卡片、列表行、输入框等常规表面。
  static Color get surfaceDefault => _p.surfaceDefault;

  /// 弹窗、浮层等需要与背景拉开层次的表面。
  static Color get surfaceRaised => _p.surfaceRaised;

  /// 频道牌衬底。⚠️ 注意首页的频道牌**不用**它，用的是半透明的
  /// [surfaceThumb]——那里有背景图，卡片要透出底图。这个值用于
  /// 无背景图的场景（弹窗内的频道牌等）。
  static Color get surfacePlate => _p.surfacePlate;

  /// 分隔线 / 描边。必须比最亮的一档表面还亮（深色）或还暗（浅色），
  /// 否则频道牌画在浮层里时边界会糊掉。
  static Color get line => _p.line;

  /// 抽屉、对话框等深色面板背景。保留此名以兼容既有调用点。
  static Color get surfacePanel => _p.surfaceDefault;

  /// 频道项缩略图背景（半透明黑）。
  ///
  /// **两种模式下都是半透明黑**——它压在背景图上，不跟随表面阶梯。
  /// 换成不透明色块会把背景图挡住，整屏变成实心色块。
  static const Color surfaceThumb = Color(0x59000000);

  /// 角标 / 标签背景。压在台标上，需在任何底色上都可读，故恒为半透明黑。
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
  static Color get focusRing => brand;

  // ========== 语义色 Semantic ==========
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ========== 源状态 Source health ==========
  //
  // ⚠️ 这两个颜色**只**用于表示源的可达性，不参与任何装饰。
  //
  // 背景：IPTV 里几乎所有频道都在直播，所以「直播中」标识是恒为真的状态，
  // 出现在每张卡片上等于什么都没区分——它不值得占用像素。真正会变化、
  // 也真正会坑到用户的是「这条源还活着吗」，那个位置留给它。
  //
  // 约定：**只标注例外**。正常的源不着一墨，没有「绿色＝正常」的标记。

  /// 上次拉流失败 / 超时。卡片同时整体降透明度。
  static const Color sourceDead = Color(0xFFFF453A);

  /// 响应慢但可用。
  static const Color sourceSlow = Color(0xFFF5A524);
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

/// 一套完整的中性色板。深浅两套同名不同值，由 [isDarkMode] 选择。
class _AppPaletteSet {
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color surfaceGround;
  final Color surfaceDefault;
  final Color surfaceRaised;
  final Color surfacePlate;
  final Color line;

  const _AppPaletteSet({
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.surfaceGround,
    required this.surfaceDefault,
    required this.surfaceRaised,
    required this.surfacePlate,
    required this.line,
  });
}
