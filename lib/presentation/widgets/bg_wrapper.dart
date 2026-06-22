import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 全局背景：静态模糊背景图 + 暗化遮罩。
///
/// 用 [ImageFiltered] 对图片本身做一次性模糊（配 [RepaintBoundary] 只绘制一次），
/// 而非 [BackdropFilter]——后者每帧采样其后方内容，前景内容一重绘背景就会闪烁。
class BgWrapper extends StatelessWidget {
  final Widget child;
  final String imagePath;
  final Color backgroundColor;

  const BgWrapper({
    super.key,
    required this.child,
    this.imagePath = 'assets/images/bg2.jpg',
    this.backgroundColor = AppTokens.scrim,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 纯黑底，避免模糊在边缘采样到透明像素时露出底色
        const ColoredBox(color: Colors.black),
        // 一次性模糊的背景图（隔离重绘，不随前景内容刷新而闪烁）
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        ),
        // 暗化遮罩
        ColoredBox(color: backgroundColor),
        // 业务内容
        child,
      ],
    );
  }
}
