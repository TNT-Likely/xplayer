import 'package:flutter/material.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

enum XIconButtonType { defaultType, primary, danger }

enum XIconButtonSize { defaultSize, large }

class XIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;
  final EdgeInsetsGeometry? padding;
  final Color? iconColor;
  final XIconButtonType type;
  final XIconButtonSize buttonSize;
  final bool hoverBgOnly;
  final String? tooltipMessage;
  final FocusNode? focusNode;
  final bool autofocus;

  /// 图标下方的文字标签(可选)。传入后纵向排布:图标在上、文字在下。
  /// 不传则维持纯图标按钮,现有调用零影响。
  final String? label;

  const XIconButton(
      {Key? key,
      required this.icon,
      this.onPressed,
      this.size,
      this.padding,
      this.iconColor,
      this.type = XIconButtonType.defaultType,
      this.buttonSize = XIconButtonSize.defaultSize,
      this.hoverBgOnly = false,
      this.tooltipMessage,
      this.focusNode,
      this.autofocus = false,
      this.label})
      : super(key: key);

  Color _getBackgroundColor(BuildContext context, bool isFocus) {
    if (hoverBgOnly && !isFocus) return Colors.transparent;
    switch (type) {
      case XIconButtonType.primary:
        return isFocus
            ? Theme.of(context).primaryColor.withOpacity(0.75)
            : Theme.of(context).primaryColor;
      case XIconButtonType.danger:
        return isFocus ? Colors.red.withOpacity(0.75) : Colors.red;
      case XIconButtonType.defaultType:
      default:
        return isFocus ? AppTokens.focusFillDefault : AppTokens.fillDefault;
    }
  }

  double _getIconSize() {
    switch (buttonSize) {
      case XIconButtonSize.defaultSize:
        return size ?? 24.0; // 默认图标大小
      case XIconButtonSize.large:
      default:
        return size ?? 36.0; // 较大的图标大小
    }
  }

  @override
  Widget build(BuildContext context) {
    return XBaseButton(
      focusNode: focusNode,
      autofocus: autofocus,
      tooltipMessage: tooltipMessage,
      onPressed: onPressed,
      child: (bool isFocus) {
        // 圆形图标容器(焦点态:品牌色柔光,去掉生硬描边)
        final Widget iconBox = Container(
          width: _getIconSize() + (padding?.horizontal ?? 16.0), // 根据内边距调整宽度
          height: _getIconSize() + (padding?.vertical ?? 16.0), // 根据内边距调整高度
          padding: padding ??
              EdgeInsets.all(
                  buttonSize == XIconButtonSize.defaultSize ? 8.0 : 12.0),
          decoration: BoxDecoration(
            color: _getBackgroundColor(context, isFocus),
            borderRadius: BorderRadius.circular(24.0),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: _getIconSize(),
            color: iconColor ?? Colors.white,
          ),
        );

        // 有标签:图标在上、文字在下;焦点时文字提亮
        final Widget content = label == null
            ? iconBox
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconBox,
                  const SizedBox(height: 3),
                  Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.0,
                      decoration: TextDecoration.none,
                      fontWeight:
                          isFocus ? FontWeight.w600 : FontWeight.normal,
                      color: isFocus
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              );

        // 焦点态仅用背景色区分(不放大/不发光,避免在受限容器内被裁剪)
        return content;
      },
    );
  }
}
