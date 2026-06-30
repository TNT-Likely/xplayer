import 'package:flutter/material.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

enum XTextButtonType { defaultType, primary, danger }

enum XTextButtonSize { defaultSize, large, flexible }

class XTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final VoidCallback? onMore;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final XTextButtonType type;
  final XTextButtonSize size;
  final FocusNode? focusNode;
  final String? tooltipMessage;
  final VoidCallback? onArrowUp;
  final VoidCallback? onArrowDown;
  final VoidCallback? onArrowLeft;
  final VoidCallback? onArrowRight;
  final bool autofocus;

  const XTextButton(
      {Key? key,
      required this.text,
      this.onPressed,
      this.onMore,
      this.width,
      this.height,
      this.padding,
      this.textStyle,
      this.type = XTextButtonType.defaultType, // 默认类型为 defaultType
      this.size = XTextButtonSize.defaultSize, // 默认尺寸为 defaultSize (之前的 small)
      this.tooltipMessage,
      this.focusNode,
      this.onArrowUp,
      this.onArrowDown,
      this.onArrowLeft,
      this.onArrowRight,
      this.autofocus = false})
      : super(key: key);

  Color _getBackgroundColor(BuildContext context, bool isFocus) {
    switch (type) {
      case XTextButtonType.primary:
        return isFocus
            ? Theme.of(context).primaryColor.withOpacity(0.75)
            : Theme.of(context).primaryColor;
      case XTextButtonType.danger:
        return isFocus ? Colors.red.withOpacity(0.75) : Colors.red;
      case XTextButtonType.defaultType:
      default:
        return isFocus ? AppTokens.focusFillDefault : AppTokens.fillDefault;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    double fontSize = _getFontSize();
    double lineHeight = fontSize * 1.4; // line-height to font-size ratio

    return TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: fontSize,
            color: Colors.white,
            height: lineHeight / fontSize,
            decoration: TextDecoration.none)
        .merge(textStyle);
  }

  double? _getWidth() {
    if (width != null) return width;

    switch (size) {
      case XTextButtonSize.defaultSize:
        return 80.0; // 固定宽度
      case XTextButtonSize.large:
        return double.maxFinite; // 使用 maxFinite 表示最大内容宽度
      case XTextButtonSize.flexible:
        return null; // 自适应宽度
    }
  }

  double _getHeight() {
    switch (size) {
      case XTextButtonSize.defaultSize:
        return height ?? 36.0; // 更小的高度
      case XTextButtonSize.large:
        return height ?? 48.0; // 中等高度
      case XTextButtonSize.flexible:
        return height ?? 36.0; // 与 defaultSize 相同的高度
    }
  }

  double _getFontSize() {
    switch (size) {
      case XTextButtonSize.defaultSize:
        return 14.0; // 更小的字体
      case XTextButtonSize.large:
        return 20.0; // 中等字体
      case XTextButtonSize.flexible:
        return 14.0; // 与 defaultSize 相同的字体大小
    }
  }

  @override
  Widget build(BuildContext context) {
    return XBaseButton(
      tooltipMessage: tooltipMessage,
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      onMore: onMore,
      onArrowUp: onArrowUp,
      onArrowDown: onArrowDown,
      onArrowLeft: onArrowLeft,
      onArrowRight: onArrowRight,
      child: (bool isFocus) {
        return AnimatedScale(
          scale: isFocus ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            width: _getWidth(),
            // 用 minHeight 而非固定 height:文字一行放不下换行时容器可增高,不裁切
            constraints: BoxConstraints(minHeight: _getHeight()),
            padding: padding ??
                EdgeInsets.symmetric(
                  horizontal: (size == XTextButtonSize.defaultSize ||
                               size == XTextButtonSize.flexible) ? 16.0 : 32.0,
                ),
            // 焦点态:轻微放大 + 品牌色柔光,去掉生硬描边
            decoration: BoxDecoration(
              color: _getBackgroundColor(context, isFocus),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: isFocus
                  ? [
                      BoxShadow(
                        color: AppTokens.focusRing.withOpacity(0.45),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: _getTextStyle(context),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
