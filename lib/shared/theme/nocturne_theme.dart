import 'package:flutter/material.dart';
import 'package:xplayer/shared/theme/theme_settings.dart';
import 'package:xplayer_ui/foundation.dart';

XpPalette appUiPalette() {
  final accent = themeColor.value;
  // 保留既有用户选色；亮色按钮使用对应的深色前景。
  return XpPalette(
    accent: accent,
    accentInk: accent.computeLuminance() > .179
        ? (accent == const Color(0xffb5e6bb)
              ? const Color(0xff17371e)
              : Colors.black)
        : Colors.white,
    accentWash: accent.withValues(alpha: .08),
  );
}
