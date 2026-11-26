import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/presentation/widgets/mini_player_overlay.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/shared/navigation.dart';
import 'package:xplayer/shared/theme/app_theme.dart';
import 'package:xplayer_ui/xplayer_ui.dart';
import '../mini/_fake_backend.dart';
import 'fakes.dart';

void main() {
  for (final spec in [
    (
      name: '手机',
      size: const Size(390, 844),
      device: XpDevice.phone,
      scale: 1.0,
    ),
    (name: 'TV', size: const Size(960, 540), device: XpDevice.tv, scale: 1.0),
    (
      name: '大字体',
      size: const Size(390, 844),
      device: XpDevice.phone,
      scale: 2.0,
    ),
  ]) {
    testWidgets('${spec.name} 小窗在 Navigator Overlay 中显示、不溢出、弹窗期间隐藏', (
      tester,
    ) async {
      tester.view.physicalSize = spec.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final media = FakeMedia();
      final mini = MiniPlayerController();
      final backend = FakeBackend();
      final page = Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: XpButton(
              label: '打开配置',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('配置'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MediaProvider>.value(value: media),
            ChangeNotifierProvider<MiniPlayerController>.value(value: mini),
          ],
          child: XpTheme(
            data: XpThemeData(device: spec.device),
            child: MaterialApp(
              navigatorKey: AppNav.key,
              navigatorObservers: [MiniPlayerNavigatorObserver()],
              theme: buildAppTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(spec.scale)),
                child: child!,
              ),
              home: page,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      mini.enterMini(backend, media.items.first, []);
      await tester.pumpAndSettle();
      expect(find.byType(XpMiniPlayer), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('打开配置'));
      await tester.pumpAndSettle();
      expect(find.byType(XpMiniPlayer), findsNothing);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      expect(find.byType(XpMiniPlayer), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('关闭迷你播放器'));
      await tester.pumpAndSettle();
      expect(mini.hasMini, isFalse);
      expect(backend.disposed, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      mini.dispose();
      media.dispose();
    });
  }
  testWidgets('44 像素缺图缩略图可以独立渲染', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 58,
            height: 44,
            child: XpArtwork(
              channel: XpChannelData(id: 'one', name: '很长的频道名称'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
