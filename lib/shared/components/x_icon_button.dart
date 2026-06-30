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
      this.autofocus = false})
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
        return Container(
          width: _getIconSize() + (padding?.horizontal ?? 16.0), // 根据内边距调整宽度
          height: _getIconSize() + (padding?.vertical ?? 16.0), // 根据内边距调整高度
          padding: padding ??
              EdgeInsets.all(
                  buttonSize == XIconButtonSize.defaultSize ? 8.0 : 12.0),
          decoration: BoxDecoration(
            color: _getBackgroundColor(context, isFocus),
            borderRadius: BorderRadius.circular(24.0),
          ),
          // 焦点描边放前景层:画在内容之上、不挤压布局,图标不会偏移
          foregroundDecoration: isFocus
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: AppTokens.focusRing, width: 2),
                )
              : null,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: _getIconSize(),
            color: iconColor ?? Colors.white,
          ),
        );
      },
    );
  }
}
