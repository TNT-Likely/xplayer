import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 用户是靠什么在操作这个界面。
///
/// **按输入能力判定，不按操作系统。** Android TV 与平板可能是同一个
/// API level、同一块屏幕尺寸，靠 `Platform.isAndroid` 根本分不开；真正决定
/// 界面形态的是「有没有指针」——有指针就有悬停态，只有方向键就必须处处可聚焦。
///
/// 副作用（而且是好处）：可以在桌面上强制切到 [remote] 来调试 TV 布局，
/// 不必每次都往电视上装包。
enum InputMode {
  /// 触摸屏。手机、平板。
  touch,

  /// 指针（鼠标 / 触控板）。桌面。有悬停态。
  pointer,

  /// 遥控器方向键。电视、机顶盒。只有焦点态，没有悬停态。
  remote;

  bool get isRemote => this == InputMode.remote;
  bool get hasPointer => this == InputMode.pointer;

  /// 该输入方式下是否存在悬停态。遥控器没有「指针悬停」这回事。
  bool get hasHover => this == InputMode.pointer;

  /// 是否必须保证每个可操作元素都能被方向键聚焦。
  bool get needsFocusTraversal => this == InputMode.remote;
}

/// 把 [InputMode] 提供给下游。
///
/// 放在 `MaterialApp` 之上，[resolveShell] 与各 Shell 都从这里取值。
class InputModeScope extends InheritedWidget {
  final InputMode mode;

  const InputModeScope({
    super.key,
    required this.mode,
    required super.child,
  });

  /// 取当前输入方式。没有祖先 scope 时按平台推断一个兜底值，
  /// 这样局部使用（例如单独跑一个 widget 测试）不会崩。
  static InputMode of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<InputModeScope>();
    return scope?.mode ?? detectInputMode();
  }

  @override
  bool updateShouldNotify(InputModeScope old) => old.mode != mode;
}

/// 覆盖值。用于「在桌面上调试 TV 布局」这类场景，也便于测试注入。
@visibleForTesting
InputMode? debugInputModeOverride;

/// 按运行平台推断默认输入方式。
///
/// 这只是**默认值**，不是最终判定：真正的 TV 判定还应结合系统特性
/// （Android 上是 `FEATURE_LEANBACK`），那需要平台通道，留给接线时补。
/// 这里保证的是「没有任何额外信息时也能给出一个合理值」。
InputMode detectInputMode() {
  if (debugInputModeOverride != null) return debugInputModeOverride!;

  if (kIsWeb) return InputMode.pointer;

  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      return InputMode.touch;
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return InputMode.pointer;
    case TargetPlatform.fuchsia:
      return InputMode.touch;
  }
}
