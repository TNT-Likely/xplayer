import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:xplayer/shared/theme/app_tokens.dart';

class BgWrapper extends StatelessWidget {
  final Widget child;
  final String imagePath;
  final Color backgroundColor;

  const BgWrapper({
    Key? key,
    required this.child,
    this.imagePath = 'assets/images/bg2.jpg', // 默认背景图片路径
    this.backgroundColor = AppTokens.scrim, // 默认背景遮罩(单层,避免叠加过暗)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: backgroundColor, // 背景颜色，用于混合模糊效果
            child: child,
          ),
        ),
      ),
    );
  }
}
