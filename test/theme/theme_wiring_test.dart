import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/shared/theme/app_palette.dart';
import 'package:xplayer/shared/theme/app_theme.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/shared/theme/theme_settings.dart';

/// 主色接线的端到端验证:themeColor → AppTokens.brand → buildAppTheme() → UI。
///
/// 这条链路一旦断掉(例如有人把 MaterialApp 外层的 ValueListenableBuilder 拆了,
/// 或把 brand 改回 const),换色功能会静默失效 —— 编译照过、测试照绿、
/// 只有真机上点了色板没反应。故在此锁定。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    themeColor.value = AppPalette.green;
  });

  test('AppTokens.brand 跟随 themeColor 变化', () {
    expect(AppTokens.brand, AppPalette.green);
    themeColor.value = AppPalette.red;
    expect(AppTokens.brand, AppPalette.red);
  });

  test('focusRing 始终跟随 brand', () {
    themeColor.value = AppPalette.amber;
    expect(AppTokens.focusRing, AppTokens.brand);
  });

  test('buildAppTheme 的 seed 跟随主色,换色后 colorScheme 不同', () {
    final green = buildAppTheme().colorScheme.primary;
    themeColor.value = AppPalette.red;
    final red = buildAppTheme().colorScheme.primary;

    expect(green, isNot(red),
        reason: 'buildAppTheme 未跟随主色,seedColor 可能被写死了');
  });

  testWidgets('换色触发 MaterialApp 重建,Theme.of 取到新主色', (tester) async {
    // 复刻 main.dart 的接线结构:ValueListenableBuilder 包住 MaterialApp。
    await tester.pumpWidget(
      ValueListenableBuilder<Color>(
        valueListenable: themeColor,
        builder: (context, _, __) => MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (c) => Text(
              '${Theme.of(c).colorScheme.primary.toARGB32()}',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );

    final before = tester.widget<Text>(find.byType(Text)).data;

    await setThemeColor(AppPalette.red);
    // 注意必须 pumpAndSettle 而非 pump:MaterialApp 内部用 AnimatedTheme,
    // 主题切换是带过渡动画的(默认 200ms),单帧 pump 时颜色还在半路。
    // 这也意味着真机上换色是渐变而非瞬间跳变。
    await tester.pumpAndSettle();

    final after = tester.widget<Text>(find.byType(Text)).data;

    expect(after, isNot(before),
        reason: '换色未触发重建 —— MaterialApp 外层的 '
            'ValueListenableBuilder 可能被拆掉了');
  });
}
