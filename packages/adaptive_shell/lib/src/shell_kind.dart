import 'package:flutter/widgets.dart';

import 'input_mode.dart';

/// 界面骨架的三种形态。
///
/// **这是全应用唯一的形态分支。** 下游所有组件都不再判断平台或尺寸，
/// 只接受参数（例如 `ChannelPlate(width: ...)`）。
///
/// 之所以强调「唯一」：仓库里原本散着 48 处 `Platform.is` / `MediaQuery` /
/// `LayoutBuilder`，分布在 10 个文件里。多形态设计最常见的死法就是
/// `if (isTV)` 继续往几十个 widget 里渗。分支数量不是问题，分布才是。
enum ShellKind {
  /// 手机竖屏、iPad 竖屏、折叠展开态。单列，轨道纵向堆叠。
  compact,

  /// 桌面、iPad 横屏。侧栏 + 主区，播放器内嵌，不做全屏跳转。
  expanded,

  /// 电视。视频铺底 + 频道浮层，只有焦点态。
  tenFoot,
}

/// 宽度断点：小于此值走 [ShellKind.compact]。
///
/// 1000 是 iPad 横屏（1024/1180）与竖屏（768/834）之间的分界。
const double kExpandedBreakpoint = 1000;

/// 判定当前该用哪套骨架。
///
/// 判定顺序有意为之：**先看输入方式，再看宽度**。
/// 电视的物理分辨率往往比桌面还大（1920/3840），按宽度判会被归到
/// [ShellKind.expanded]，于是拿到一套需要鼠标悬停的界面 —— 遥控器没法用。
ShellKind resolveShell(BuildContext context) {
  if (InputModeScope.of(context).isRemote) return ShellKind.tenFoot;
  return MediaQuery.sizeOf(context).width < kExpandedBreakpoint
      ? ShellKind.compact
      : ShellKind.expanded;
}

/// 不依赖 context 的判定，便于单测与在已知参数处直接调用。
ShellKind resolveShellFrom({
  required InputMode input,
  required double width,
}) {
  if (input.isRemote) return ShellKind.tenFoot;
  return width < kExpandedBreakpoint ? ShellKind.compact : ShellKind.expanded;
}

/// 卡片建议宽度。同一个 [ChannelPlate] 在三种骨架下只是参数不同，
/// 不存在三份实现。
double channelCardWidth(ShellKind kind, double screenWidth) {
  switch (kind) {
    case ShellKind.compact:
      // 竖屏放大一档:iPad 竖屏比手机宽得多,卡片跟着大才不显得空。
      return screenWidth >= 600 ? 148 : 104;
    case ShellKind.expanded:
      return 132;
    case ShellKind.tenFoot:
      // 十英尺观看距离,整体上调。
      return 118;
  }
}
