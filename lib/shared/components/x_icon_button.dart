import 'package:flutter/material.dart';
import 'package:xplayer/shared/components/x_base_button.dart';

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
      this.tooltipMessage})
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
        return isFocus
            ? Colors.white.withOpacity(0.25)
            : Colors.white.withOpacity(0.15);
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
