/// 多端界面骨架判定。
///
/// 多形态设计最常见的死法是 `if (isTV)` 散进几十个 widget。这个包的全部作用
/// 就是把形态分支**收敛到唯一一处**，下游组件不再判断平台或尺寸，只接受参数。
///
/// ## 两条判定原则
///
/// **一、按输入能力判定，不按操作系统。** Android TV 与平板可能是同一个
/// API level、同一块屏幕尺寸，靠 `Platform.isAndroid` 根本分不开；真正决定
/// 界面形态的是「有没有指针」——有指针就有悬停态，只有方向键就必须处处可聚焦。
///
/// **二、先看输入，再看宽度。** 电视的物理分辨率往往比桌面还大（1920/3840），
/// 按宽度判会被归到 [ShellKind.expanded]，于是拿到一套需要鼠标悬停的界面，
/// 遥控器没法用。
///
/// ```dart
/// // 应用根部注入
/// InputModeScope(mode: detectInputMode(), child: MyApp())
///
/// // 唯一的形态分支
/// switch (resolveShell(context)) {
///   ShellKind.compact  => CompactHome(vm),
///   ShellKind.expanded => ExpandedHome(vm),
///   ShellKind.tenFoot  => TenFootHome(vm),
/// }
/// ```
///
/// 副产品：可在桌面上把 [debugInputModeOverride] 设成 [InputMode.remote]
/// 来调试 TV 布局，不必每次往电视上装包。
library adaptive_shell;

export 'src/input_mode.dart';
export 'src/shell_kind.dart';
