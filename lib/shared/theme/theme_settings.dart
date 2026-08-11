import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/shared/theme/app_palette.dart';

/// 主题强调色:驱动焦点高亮、按钮、选中态、进度条、Switch 激活色。
/// 背景与文字保持深色方案,不受此值影响。
///
/// 模式与 lib/utils/player_settings.dart 的各项设置一致:
/// 全局 ValueNotifier + load/set 函数 + SharedPreferences,存取异常静默吞掉
/// (设置读写失败不该让 app 挂掉,退回默认值即可)。
final ValueNotifier<Color> themeColor = ValueNotifier<Color>(AppPalette.green);

const String _kThemeColorKey = 'theme_color';

Future<void> loadThemeColor() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kThemeColorKey);
    if (v != null) themeColor.value = Color(v);
  } catch (_) {}
}

Future<void> setThemeColor(Color c) async {
  themeColor.value = c;
  try {
    final prefs = await SharedPreferences.getInstance();
    // Flutter 3.27+ 起 Color.value 已废弃,用 toARGB32()。
    await prefs.setInt(_kThemeColorKey, c.toARGB32());
  } catch (_) {}
}
