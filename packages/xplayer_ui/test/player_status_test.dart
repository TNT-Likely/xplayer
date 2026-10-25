import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

void main() {
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
