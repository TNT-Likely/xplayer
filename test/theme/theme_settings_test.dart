import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/shared/theme/app_palette.dart';
import 'package:xplayer/shared/theme/theme_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 每个用例前复位全局 notifier,避免用例间互相污染
    themeColor.value = AppPalette.green;
  });

  group('themeColor 持久化', () {
    test('无存储值时保持默认绿色', () async {
      SharedPreferences.setMockInitialValues({});
      await loadThemeColor();
      expect(themeColor.value, AppPalette.green);
    });

    test('setThemeColor 立即更新 notifier 并写入存储', () async {
      SharedPreferences.setMockInitialValues({});
      await setThemeColor(AppPalette.blue);

      expect(themeColor.value, AppPalette.blue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_color'), AppPalette.blue.toARGB32());
    });

    test('load 读回此前存入的颜色', () async {
      SharedPreferences.setMockInitialValues(
          {'theme_color': AppPalette.orange.toARGB32()});
      await loadThemeColor();
      expect(themeColor.value, AppPalette.orange);
    });

    test('存储里是任意自定义色值时也能原样读回(为后续取色器留出空间)', () async {
      const custom = Color(0xFF123456);
      SharedPreferences.setMockInitialValues({'theme_color': custom.toARGB32()});
      await loadThemeColor();
      expect(themeColor.value.toARGB32(), custom.toARGB32());
    });

    test('notifier 变更会通知监听者', () async {
      SharedPreferences.setMockInitialValues({});
      var notified = 0;
      void listener() => notified++;
      themeColor.addListener(listener);

      await setThemeColor(AppPalette.red);
      themeColor.removeListener(listener);

      expect(notified, 1);
    });
  });
}
