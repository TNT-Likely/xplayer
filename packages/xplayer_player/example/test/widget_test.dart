import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player_example/main.dart';

void main() {
  testWidgets('a fresh host opens without native media or application data', (
    tester,
  ) async {
    await tester.pumpWidget(const PlayerExample());
    expect(find.text('XPlayer 独立接入示例'), findsOneWidget);
    expect(find.text('输入地址后加载播放'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'not-a-url');
    await tester.tap(find.text('加载 / 重试'));
    await tester.pump();
    expect(find.textContaining('请输入完整播放地址'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
