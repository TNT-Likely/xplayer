import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

typedef VoidCallback = void Function();

typedef ChildCallback = Widget Function(bool isFocus);

class XBaseButton extends StatefulWidget {
  final ChildCallback child;
  final VoidCallback? onPressed;
  final VoidCallback? onMore; // 新增的回调函数
  final String? tooltipMessage;
  final ValueChanged<bool>? onFocusChange; // 新增的焦点变化回调

  const XBaseButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.onMore, // 可选的更多操作回调
    this.tooltipMessage, // 可选的 Tooltip 消息
    this.onFocusChange, // 焦点变化时的回调
  }) : super(key: key);

  @override
  State<XBaseButton> createState() => _XBaseButtonState();

  // 添加一个静态方法，用于从 GlobalKey 调用 requestFocus 方法
  static void requestFocus(GlobalKey<State<XBaseButton>> key) {
    final state = key.currentState as _XBaseButtonState?;
    state?.requestFocus();
  }
}

class _XBaseButtonState extends State<XBaseButton> with WidgetsBindingObserver {
  late final FocusNode _focusNode;
  bool _isFocus = false;
  bool _isHovered = false;
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);

    _focusNode.addListener(() {
      setState(() {
        _isFocus = _focusNode.hasFocus || _isHovered;
      });
      if (widget.tooltipMessage != null) {
        // 当获得焦点时显示 Tooltip
        _toggleTooltip(_isFocus);
      }
      // 触发 onFocusChange 回调
      if (widget.onFocusChange != null) {
        widget.onFocusChange!(_isFocus);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  DateTime? start;

  /// 更新或重置按下时间
  void updateStart(DateTime? time) {
    setState(() {
      if (time != null) {
        // 如果传入非空时间，则更新按下时间
        start = time;
      } else {
        // 如果传入 null，则重置按下时间
        start = null;
      }
    });
  }

  void _handleKeyPress(RawKeyEvent event) {
    // 记录按下时间
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.select) {
      if (start == null) {
        updateStart(DateTime.now());
      }
    }
    // TV端菜单事件
    if (widget.onMore != null &&
        (event.logicalKey == LogicalKeyboardKey.contextMenu)) {
      widget.onMore!();
    }

    // 模拟TV端长按事件
    if (event is RawKeyUpEvent &&
        event.logicalKey == LogicalKeyboardKey.select) {
      if (start == null) return;

      int duration = DateTime.now().difference(start!).inMilliseconds;
      bool longPress = duration > 500;

      if (longPress && widget.onMore != null) {
        widget.onMore!();
      }
      if (!longPress && widget.onPressed != null) {
        widget.onPressed!();
      }

      updateStart(null);
    }

    if (Platform.isWindows || Platform.isMacOS) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (widget.onPressed != null) {
          widget.onPressed!();
        }
      }
    }
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  void _handleLongPress() {
    if (widget.onMore != null) {
      widget.onMore!();
    }
  }

  void _handleRightClick(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kSecondaryMouseButton) {
      if (widget.onMore != null) {
        widget.onMore!();
      }
    }
  }

  void _toggleTooltip(bool show) {
    if (show) {
      _tooltipKey.currentState?.ensureTooltipVisible();
    } else {
      Tooltip.dismissAllToolTips();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
          _isFocus = true; // 鼠标悬停时也视为聚焦
        });
        _toggleTooltip(true); // 鼠标悬停时显示 Tooltip
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _isFocus = _focusNode.hasFocus; // 只有当键盘聚焦时才保持聚焦状态
        });
        _toggleTooltip(false); // 鼠标移出时隐藏 Tooltip
      },
      child: widget.child(_isFocus || _isHovered),
    );

    // 如果提供了 tooltipMessage，则包裹在 Tooltip 中，并设置为手动触发
    final Widget wrappedContent = widget.tooltipMessage != null
        ? Tooltip(
            key: _tooltipKey,
            message: widget.tooltipMessage!,
            triggerMode: TooltipTriggerMode.manual,
            showDuration: const Duration(seconds: 2), // 显示持续时间
            waitDuration: Duration.zero, // 不等待立即显示
            child: content,
          )
        : content;

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress, // 触控屏长按
      child: RawKeyboardListener(
          focusNode: _focusNode,
          onKey: _handleKeyPress,
          child: Listener(
              onPointerDown: _handleRightClick, child: wrappedContent)),
    );
  }

  /// 公开的方法，允许外部请求焦点
  void requestFocus() {
    _focusNode.requestFocus();
  }
}
