import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 遥控器(D-pad)友好的输入框包装。
///
/// 痛点:TV 上焦点进了单行 TextField 就出不来——左/右被光标吃掉,
/// 上/下又常被外层的滚动键处理器吃掉,导致"卡死在搜索框"。
///
/// 用法:把 TextField 包一层 `DpadEscapable(child: TextField(...))`。
/// 它在输入框获焦时拦截上/下键,把焦点按方向移出输入框(交给焦点遍历),
/// 从而总能离开。其它键照常传给输入框。
///
/// 约定:**TV 可见页面里的所有 TextField 都用它包一层**,避免重蹈覆辙。
class DpadEscapable extends StatelessWidget {
  final Widget child;
  const DpadEscapable({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Focus(
      // skipTraversal: 让它本身不抢焦点,只做按键拦截;焦点仍落在内部 TextField 上。
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final k = event.logicalKey;
        if (k == LogicalKeyboardKey.arrowUp) {
          FocusScope.of(context).focusInDirection(TraversalDirection.up);
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowDown) {
          FocusScope.of(context).focusInDirection(TraversalDirection.down);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
