import 'package:flutter/material.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 通用主题化卡片容器（参考 BeeCount 的 SectionCard）。
///
/// 纯样式封装：圆角 + 深色面板表面 + 内边距，**不含任何焦点逻辑**。
/// 需要在 TV 上可聚焦时，请用 [XBaseButton]/[XTextButton] 包裹其子内容——
/// 本组件只负责"长相"，焦点交给既有 TV 封装，二者职责分离。
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.s12),
    this.color,
    this.radius = AppDimens.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTokens.surfacePanel,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
