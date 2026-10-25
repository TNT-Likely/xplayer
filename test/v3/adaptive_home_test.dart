import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/adaptive/app_layout.dart';
import 'package:xplayer/presentation/screens/home.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/locale_provider.dart';
import 'package:xplayer/providers/remote_provider.dart';
import 'package:xplayer/shared/theme/app_theme.dart';
import 'package:xplayer_ui/xplayer_ui.dart';
import 'fakes.dart';

Widget app(FakeMedia media, {bool tv = false, double scale = 1}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MediaProvider>.value(value: media),
        ChangeNotifierProvider<GlobalProvider>(
          create: (_) => FakeGlobal(tv: tv),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => RemoteProvider()),
      ],
      child: XpTheme(
        data: XpThemeData(device: tv ? XpDevice.tv : XpDevice.phone),
        child: MaterialApp(
          theme: buildAppTheme(),
          locale: const Locale('zh'),
          supportedLocales: const [Locale('zh')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const HomeScreen(startRemoteServer: false),
        ),
      ),
    );
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('输入方式独立于窗口尺寸，TV 不由宽度推断', () {
    const desktop = AppLayout(
      width: 390,
      isTv: false,
      platform: TargetPlatform.macOS,
    );
    expect(desktop.input, XpInputMode.pointer);
    expect(desktop.useBottomNavigation, isTrue);
    const tv = AppLayout(
      width: 960,
      isTv: true,
      platform: TargetPlatform.android,
    );
    expect(tv.device, XpDevice.tv);
    expect(tv.useBottomNavigation, isFalse);
    expect(tv.channelColumns(700), 2);
    expect(
      const AppLayout(
        width: 1920,
        isTv: false,
        platform: TargetPlatform.macOS,
      ).device,
      XpDevice.desktop,
    );
  });
  for (final scenario in [
    (const Size(390, 844), false, 1.0),
    (const Size(1194, 834), false, 1.0),
    (const Size(1440, 960), false, 1.0),
    (const Size(1920, 1080), true, 1.0),
    (const Size(960, 540), true, 1.0),
    (const Size(320, 740), false, 2.0),
  ]) {
    testWidgets('真实主页面 ${scenario.$1} TV=${scenario.$2} 字号=${scenario.$3}', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final media = FakeMedia();
      await tester.pumpWidget(app(media, tv: scenario.$2, scale: scenario.$3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (scenario.$2 && scenario.$1.height == 540) {
        final play = find.widgetWithText(TextButton, '立即观看');
        expect(
          tester.getRect(play).bottom,
          lessThanOrEqualTo(540),
          reason: '矮 TV 的主播放操作应在首屏可见',
        );
      }
      for (final section in [
        'channels',
        'guide',
        'favorites',
        'settings',
        'home',
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey('nav-$section')));
        await tester.tap(find.byKey(ValueKey('nav-$section')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: section);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('搜索、分组和收藏连接到真实 Provider 接口', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final media = FakeMedia();
    await tester.pumpWidget(app(media));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-channels')));
    await tester.pumpAndSettle();
    final search = find.descendant(
      of: find.byType(XpSearchField),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, '一台');
    await tester.pumpAndSettle();
    expect(media.filteredChannels.single.id, 'one');
    final favourite = find.byTooltip('收藏 测试一台');
    await tester.ensureVisible(favourite);
    await tester.tap(favourite);
    await tester.pumpAndSettle();
    expect(media.favorites.single.id, 'one');
    await tester.tap(find.byKey(const ValueKey('nav-favorites')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('取消收藏 测试一台'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
