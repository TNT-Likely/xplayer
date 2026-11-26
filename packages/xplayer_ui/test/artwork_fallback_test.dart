import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

void main() {
  testWidgets('无封面使用包内设计图，刷新后仍使用同一背景', (tester) async {
    Future<void> render() => tester.pumpWidget(const MaterialApp(
            home: SizedBox(
          width: 300,
          height: 180,
          child: XpArtwork(channel: XpChannelData(id: 'cctv1', name: 'CCTV-1')),
        )));
    await render();
    final initial = tester.widget<Image>(find.byType(Image)).image;
    expect(initial, isA<AssetImage>());
    expect((initial as AssetImage).assetName, startsWith('assets/backdrops/'));
    expect(initial.package, 'xplayer_ui');
    await render();
    expect(tester.widget<Image>(find.byType(Image)).image, initial);
    expect(find.byType(XpIcon), findsNothing);
  });

  testWidgets('真实封面加载失败也使用本地设计图', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: SizedBox(
      width: 300,
      height: 180,
      child: XpArtwork(
          channel: XpChannelData(
              id: 'sports',
              name: '体育频道',
              artwork: MemoryImage(Uint8List.fromList([1, 2, 3])))),
    )));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image ==
                const AssetImage('assets/backdrops/sport.jpg',
                    package: 'xplayer_ui')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
