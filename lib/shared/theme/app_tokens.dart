import 'package:flutter/material.dart';
import 'package:xplayer/shared/theme/theme_settings.dart';

/// XPlayer Design Token 系统（结构参考 BeeCount 的 BeeTokens / BeeDimens）。
///
/// 设计理念：语义化命名统一管理颜色与尺寸，UI 组件应使用 Token 而非散落的字面量。
/// 现状：单一深色主题（TV / IPTV 场景），**暂未引入浅色模式**。
/// 除强调色 [brand] / [focusRing] 外全部为静态常量，无需 context，
/// 便于在 CustomPainter、默认参数等无 context 处复用。
/// 强调色由用户设定（见 theme_settings.dart），故为 getter；其余保持 const，
/// 以免破坏 `const TextStyle(...)` 等现有 const 上下文。
///
/// **关于浅色模式**：需要把这里全部改成 `static Color xxx(BuildContext)`
/// 形式（见 BeeTokens），那会波及每一处调用点。这是独立的一件事，
/// 不要顺手掺进别的改动里做——先把色板本身收敛好，再统一切换取值方式。
///
/// 配色取向：中性色一律带轻微冷偏（蓝向）。纯中性灰读起来像没选过色，
/// 冷偏则读起来是有意为之，也与视频内容的冷调更协调。
class AppTokens {
  AppTokens._();

  // ========== 品牌色 Brand ==========
  /// 主色种子。由用户在「界面 → 主题色」中设定，默认 #00DC82。
  static Color get brand => themeColor.value;

  // ========== 文字 Text ==========
  /// 正文。冷偏的近白色，而非纯白——纯白在深色底上偏「刺」，
  /// 且与下面的表面阶梯同属蓝向，整体才像一套配色而非拼凑。
  static const Color textPrimary = Color(0xFFE9EEF4);
  static const Color textSecondary = Color(0xFF94A2B1);

  /// 等宽副行（分组、地区、时间码）这类次级信息。
  ///
  /// 取值受最亮的一档表面（[surfacePlate]）约束：更暗会掉到 3:1 以下，
  /// 在浮起层与牌面上都读不清。真正「几乎不可见」的角色交给 [textDisabled]。
  static const Color textTertiary = Color(0xFF7A8896);

  static const Color textDisabled = Color(0xFF46525E);

  // ========== 图标 Icon ==========
  static const Color iconPrimary = Color(0xFFE9EEF4);
  static const Color iconSecondary = Color(0xFF94A2B1);

  // ========== 背景 / 表面 Surface ==========
  //
  // 四级阶梯，越靠上越「浮起」。全部带轻微冷偏（蓝向）——
  // 纯中性灰读起来像没选过色，冷偏则读起来是有意为之。
  //
  // 阶梯关系：ground（页面底）< surface（卡片/面板）
  //          < raised（弹窗/浮层）< plate（频道牌衬底）

  /// 页面底色。
  static const Color surfaceGround = Color(0xFF0A0E13);

  /// 卡片、列表行、输入框等常规表面。
  static const Color surfaceDefault = Color(0xFF131A22);

  /// 弹窗、浮层等需要与背景拉开层次的表面。
  static const Color surfaceRaised = Color(0xFF1D2731);

  /// 频道牌衬底。比其它表面更亮一档，目的是让**透明台标也看得见**——
  /// 这是统一频道牌能成立的前提。
  static const Color surfacePlate = Color(0xFF252F3A);

  /// 分隔线 / 描边。
  ///
  /// 必须比最亮的一档表面（[surfacePlate]）还亮 —— 否则频道牌画在浮层里时
  /// 边界会糊掉。深色主题里相邻表面的亮度差本就极小，层次感实际是描边给的，
  /// 不是亮度差给的，所以这个令牌不能跟着表面阶梯一起压暗。
  static const Color line = Color(0xFF33404D);

  /// 抽屉、对话框等深色面板背景。
  ///
  /// 保留此名以兼容既有调用点；取值已并入表面阶梯（原 #222222 中性灰）。
  static const Color surfacePanel = surfaceDefault;

  /// 频道项缩略图背景（半透明黑 0.35）。
  static const Color surfaceThumb = Color(0x59000000);

  /// 角标 / 标签背景（black54）。压在台标上，需在任何底色上都可读，
  /// 故保持半透明黑而非跟随表面阶梯。
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
