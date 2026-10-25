import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

void main() {
  for (final scenario in [
    (const Size(320, 740), XpDevice.phone, 2.0),
    (const Size(1194, 834), XpDevice.ipad, 1.0),
    (const Size(1440, 900), XpDevice.desktop, 1.0),
    (const Size(960, 540), XpDevice.tv, 1.0),
  ]) {
    testWidgets('失败、格式不支持和音频状态在 ${scenario.$2} 内居中且可操作', (tester) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      for (final phase in [
        XpPlaybackPhase.error,
        XpPlaybackPhase.unsupported,
        XpPlaybackPhase.audioOnly
      ]) {
        final theme = XpThemeData(device: scenario.$2);
        await tester.pumpWidget(XpTheme(
            data: theme,
            child: MaterialApp(
              theme: theme.materialTheme(),
              home: MediaQuery(
                  data: MediaQueryData(
                      textScaler: TextScaler.linear(scenario.$3)),
                  child: Scaffold(
                    body: XpPlayerStatusView(
                        phase: phase,
                        channelName: '测试频道',
                        onRetry: () => retries++,
                        onToggleAudio: () => retries++,
                        onSwitchSource: () {},
                        onSwitchChannel: () {}),
                  )),
            )));
        await tester.pumpAndSettle();
        expect(find.byType(XpEmptyState), findsNothing);
        final content = tester.getRect(find.byType(Column));
        expect(content.center.dy, closeTo(scenario.$1.height / 2, 1));
        expect(content.left, greaterThanOrEqualTo(24));
        expect(content.right, lessThanOrEqualTo(scenario.$1.width - 24));
        if (scenario.$2 == XpDevice.tv) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        } else {
          await tester.tap(find.byType(XpButton).first);
        }
        expect(tester.takeException(), isNull);
      }
      expect(retries, 3);
    });
  }
  for (final phase in [
    XpPlaybackPhase.connecting,
    XpPlaybackPhase.buffering,
  ]) {
    testWidgets('$phase 仅在视频中央显示转圈，并保留画面和点击操作', (tester) async {
      var taps = 0;
      final theme = XpThemeData(device: XpDevice.ipad);
      await tester.pumpWidget(XpTheme(
        data: theme,
        child: MaterialApp(
          home: Scaffold(
            body:
                Stack(key: const Key('video'), fit: StackFit.expand, children: [
              GestureDetector(
                onTap: () => taps++,
                child: const ColoredBox(color: Colors.blue),
              ),
              XpPlayerStatusView(
                phase: phase,
                channelName: '测试频道',
                onRetry: () {},
                onSwitchChannel: () {},
              ),
            ]),
          ),
        ),
      ));
      final spinner = find.byType(CircularProgressIndicator);
      expect(spinner, findsOneWidget);
      expect(tester.getSize(spinner), const Size.square(28));
      expect(tester.getCenter(spinner),
          tester.getCenter(find.byKey(const Key('video'))));
      expect(find.byType(XpEmptyState), findsNothing);
      expect(find.byType(Text), findsNothing);
      await tester.tapAt(tester.getCenter(spinner));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
