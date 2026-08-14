import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 外观模式。
enum AppThemeMode { system, light, dark }

const String _prefsKey = 'app_theme_mode';

/// 当前外观模式。
///
/// 与 [themeColor] 同一套机制：可变的全局 notifier + MaterialApp 重建。
/// 这样 [AppTokens] 的颜色可以保持静态 getter 的形态，
/// 不必改成 `Color xxx(BuildContext)` 去波及每一处调用点。
final ValueNotifier<AppThemeMode> appThemeMode =
    ValueNotifier<AppThemeMode>(AppThemeMode.dark);

/// 当前是否深色。
///
/// `system` 跟随系统时用 [PlatformDispatcher] 取值 —— 它不需要 context，
/// 因此 [AppTokens] 在 CustomPainter、默认参数等无 context 处仍可用。
bool get isDarkMode {
  switch (appThemeMode.value) {
    case AppThemeMode.light:
      return false;
    case AppThemeMode.dark:
      return true;
    case AppThemeMode.system:
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  }
}

/// 映射到 Flutter 的 ThemeMode，用于 MaterialApp。
ThemeMode get materialThemeMode {
  switch (appThemeMode.value) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
}

Future<void> loadThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_prefsKey);
    // 默认深色:这是个视频应用,深色是主场景。老用户升级后观感不变。
    appThemeMode.value = switch (v) {
      'light' => AppThemeMode.light,
      'system' => AppThemeMode.system,
      _ => AppThemeMode.dark,
    };
  } catch (_) {
    // 读不到偏好不该拦住启动。
  }
}

Future<void> setThemeMode(AppThemeMode mode) async {
  appThemeMode.value = mode;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  } catch (_) {}
}

/// 系统外观变化时通知监听者（仅在跟随系统模式下有意义）。
///
/// [PlatformDispatcher.platformBrightness] 变化不会自动触发我们的 notifier，
/// 需要在 `WidgetsBindingObserver.didChangePlatformBrightness` 里调这个。
void notifySystemBrightnessChanged() {
  if (appThemeMode.value == AppThemeMode.system) {
    // 值没变但派生的 isDarkMode 变了，强制通知一次让 MaterialApp 重建。
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    appThemeMode.notifyListeners();
  }
}
