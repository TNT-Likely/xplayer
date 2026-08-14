import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/components/channel_plate.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

Channel _ch({
  String name = 'CCTV-1 综合',
  String? quality,
  String? logo,
}) =>
    Channel(
      id: 'CCTV1.CN',
      name: name,
      quality: quality,
      logo: logo,
      source: [
        Source(
          title: 't',
          link: 'http://a/x.m3u8',
          groupTitle: 'News',
          attributes: const {},
          duration: -1,
        )
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 400),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: AppTokens.surfaceGround,
        body: Center(child: SizedBox(width: size.width, child: child)),
      ),
    ),
  );
}

/// 取牌面那一层 Container（带 surfacePlate 底色的那个）。
Container _plateBox(WidgetTester tester) {
  return tester.widgetList<Container>(find.byType(Container)).firstWhere((c) {
    final d = c.decoration;
    return d is BoxDecoration && d.color == AppTokens.surfaceThumb;
  });
}

void main() {
  group('牌面基本形态', () {
    testWidgets('默认 16:9 —— 与网格 childAspectRatio 16/12 的高度预算配套', (tester) async {
      await _pump(tester, ChannelPlate(channel: _ch(), width: 200));
      final ar = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(ar.aspectRatio, 16 / 9);
    });

    testWidgets('比例可覆盖,但改了必须同步改网格', (tester) async {
      await _pump(tester,
          ChannelPlate(channel: _ch(), width: 200, aspectRatio: 16 / 10));
      final ar = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(ar.aspectRatio, 16 / 10);
    });

    testWidgets('衬底半透明 —— 首页有背景图,卡片要透出底图而不是实心色块',
        (tester) async {
      await _pump(tester, ChannelPlate(channel: _ch(), width: 200));
      final d = _plateBox(tester).decoration as BoxDecoration;
      expect(d.color, AppTokens.surfaceThumb);
      expect(d.color!.a, lessThan(1.0));
    });

    testWidgets('衬底可覆盖 —— 无背景图的场景(如弹窗内)可换成不透明档',
        (tester) async {
      await _pump(
        tester,
        ChannelPlate(
            channel: _ch(), width: 200, background: AppTokens.surfacePlate),
      );
      final box = tester.widgetList<Container>(find.byType(Container)).firstWhere(
          (c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppTokens.surfacePlate;
      });
      expect((box.decoration as BoxDecoration).color, AppTokens.surfacePlate);
    });

    testWidgets('不同 width 下都不溢出', (tester) async {
      for (final w in [80.0, 104.0, 118.0, 148.0, 240.0]) {
        await _pump(tester, ChannelPlate(channel: _ch(quality: 'HD'), width: w),
            size: Size(w + 40, 400));
        expect(tester.takeException(), isNull, reason: 'width=$w 时溢出');
      }
    });
  });

  group('清晰度角标', () {
    testWidgets('有清晰度时显示', (tester) async {
      await _pump(tester, ChannelPlate(channel: _ch(quality: 'HD'), width: 200));
      expect(find.text('HD'), findsOneWidget);
    });

    testWidgets('无清晰度时不显示,不留空位', (tester) async {
      await _pump(tester, ChannelPlate(channel: _ch(), width: 200));
      expect(find.text('HD'), findsNothing);
      expect(find.text('SD'), findsNothing);
    });

    testWidgets('用等宽字体 —— 清晰度是数据,要能和时间码对齐', (tester) async {
      await _pump(tester, ChannelPlate(channel: _ch(quality: '4K'), width: 200));
      final t = tester.widget<Text>(find.text('4K'));
      expect(t.style?.fontFamily, 'monospace');
    });
  });

  group('源健康度 —— 只标注例外', () {
    testWidgets('unknown 不显示任何标记', (tester) async {
      await _pump(tester,
          ChannelPlate(channel: _ch(), width: 200, health: SourceHealth.unknown));
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('ok 同样不显示 —— 没有「绿点＝正常」这回事', (tester) async {
      await _pump(tester,
          ChannelPlate(channel: _ch(), width: 200, health: SourceHealth.ok));
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('dead 整体压暗 —— 红点太小,一屏几十张卡里扫不出来', (tester) async {
      await _pump(tester,
          ChannelPlate(channel: _ch(), width: 200, health: SourceHealth.dead));
      final o = tester.widget<Opacity>(find.byType(Opacity));
      expect(o.opacity, lessThan(0.6));
    });

    testWidgets('slow 不压暗 —— 它仍然能看', (tester) async {
      await _pump(tester,
          ChannelPlate(channel: _ch(), width: 200, health: SourceHealth.slow));
      expect(find.byType(Opacity), findsNothing);
    });
  });

  group('焦点态', () {
    testWidgets('聚焦时画焦点环,且用 foregroundDecoration —— 不进入布局,不挤开邻居',
        (tester) async {
      await _pump(
          tester, ChannelPlate(channel: _ch(), width: 200, focused: true));
      final box = _plateBox(tester);
      expect(box.foregroundDecoration, isNotNull);
      final fg = box.foregroundDecoration as BoxDecoration;
      expect(fg.border, isNotNull);
    });

    testWidgets('未聚焦时没有焦点环', (tester) async {
      await _pump(tester, ChannelPlate(channel: _ch(), width: 200));
      expect(_plateBox(tester).foregroundDecoration, isNull);
    });

    testWidgets('聚焦不改变牌面尺寸 —— 刻意不用缩放,电视上邻居位移看着晃',
        (tester) async {
      await _pump(tester, ChannelPlate(channel: _ch(), width: 200));
      final unfocused = tester.getSize(find.byType(AspectRatio));
      await _pump(
          tester, ChannelPlate(channel: _ch(), width: 200, focused: true));
      expect(tester.getSize(find.byType(AspectRatio)), unfocused);
    });
  });

  group('无台标降级', () {
    testWidgets('没有 logo 时退回文字牌面,不留白', (tester) async {
      await _pump(tester, ChannelPlate(channel: _ch(name: '湖南卫视'), width: 200));
      expect(find.text('湖南卫视'), findsOneWidget);
    });

    testWidgets('logo 为空白串同样退回文字', (tester) async {
      await _pump(
          tester, ChannelPlate(channel: _ch(logo: '   '), width: 200));
      expect(find.text('CCTV-1 综合'), findsOneWidget);
    });

    testWidgets('名字也为空时给占位符,牌面不空着', (tester) async {
      await _pump(tester, ChannelPlate(channel: _ch(name: ''), width: 200));
      expect(find.text('—'), findsOneWidget);
    });
  });

  group('叠加层', () {
    testWidgets('overlay 能盖在牌面上', (tester) async {
      await _pump(
        tester,
        ChannelPlate(
          channel: _ch(),
          width: 200,
          overlay: const Icon(Icons.play_circle, key: Key('ov')),
        ),
      );
      expect(find.byKey(const Key('ov')), findsOneWidget);
    });
  });
}
