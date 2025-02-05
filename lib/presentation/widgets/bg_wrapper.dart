import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class BgWrapper extends StatelessWidget {
  final Widget child;
  final String imagePath;
  final Color backgroundColor;

  const BgWrapper({
    Key? key,
    required this.child,
    this.imagePath = 'assets/images/bg2.jpg', // 默认背景图片路径
    this.backgroundColor = const Color.fromRGBO(0, 0, 0, 0.5), // 默认背景颜色
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
