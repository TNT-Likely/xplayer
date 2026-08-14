import 'package:adaptive_shell/adaptive_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/components/channel_rail.dart';
import 'package:xplayer/presentation/components/rail_home_body.dart';

Channel _ch(String name, {String group = 'News'}) => Channel(
      id: name.toUpperCase(),
      name: name,
      source: [
        Source(
          title: name,
          link: 'http://a/$name.m3u8',
          groupTitle: group,
          attributes: const {},
          duration: -1,
        )
      ],
    );

List<Channel> _many(String group, int n) =>
    [for (var i = 0; i < n; i++) _ch('$group-$i', group: group)];

late List<String> _overflows;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 800),
  double textScale = 1.0,
  InputMode input = InputMode.touch,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _overflows = <String>[];
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    final s = d.exceptionAsString();
    if (s.contains('overflowed')) {
      _overflows.add(s);
    } else {
      prev?.call(d);
    }
  };
  addTearDown(() => FlutterError.onError = prev);

  // 轨道里的卡片直接复用 ChannelItemWidget，它依赖 MediaProvider
  // （收藏状态、频道刷新）。这里给一个真实实例——正因为复用了同一个卡片，
  // 轨道才自动继承了它的点击/焦点/溢出防护，测试也应当测真东西。
  await tester.pumpWidget(ChangeNotifierProvider<MediaProvider>(
    create: (_) => MediaProvider(),
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: InputModeScope(
          mode: input,
          child: Scaffold(body: child),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void _expectNoOverflow() {
  expect(_overflows, isEmpty, reason: '溢出:\n${_overflows.join("\n")}');
}

void main() {
  group('ChannelRail', () {
    testWidgets('空列表不占位 —— 没有内容的轨道不该留一条空标题', (tester) async {
      await _pump(tester,
          const ChannelRail(title: '收藏', channels: [], cardWidth: 104));
      expect(find.text('收藏'), findsNothing);
    });

    testWidgets('显示标题与数量', (tester) async {
      await _pump(
          tester,
          ChannelRail(
              title: '新闻', channels: _many('News', 5), cardWidth: 104));
      expect(find.text('新闻'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('没传 onSeeAll 时不显示「全部」', (tester) async {
      await _pump(
          tester,
          ChannelRail(
              title: '新闻', channels: _many('News', 5), cardWidth: 104));
      expect(find.text('全部 ›'), findsNothing);
    });

    testWidgets('各档卡片宽度都不溢出', (tester) async {
      for (final w in [80.0, 104.0, 118.0, 148.0, 240.0]) {
        await _pump(
            tester,
            ChannelRail(
                title: '新闻', channels: _many('News', 6), cardWidth: w));
        _expectNoOverflow();
      }
    });

    testWidgets('文字放大 1.6 倍不溢出', (tester) async {
      await _pump(
        tester,
        ChannelRail(title: '新闻', channels: _many('News', 6), cardWidth: 104),
        textScale: 1.6,
      );
      _expectNoOverflow();
    });
  });

  group('RailHomeBody', () {
    Widget body({
      List<Channel>? channels,
      List<Channel>? recent,
      List<Channel>? favorites,
    }) =>
        RailHomeBody(
          channels: channels ?? [..._many('News', 6), ..._many('Sports', 4)],
          recentChannels: recent ?? _many('News', 3),
          favoriteChannels: favorites ?? _many('Sports', 3),
        );

    testWidgets('渲染最近与收藏两条轨道', (tester) async {
      await _pump(tester, body());
      expect(find.text('最近观看'), findsOneWidget);
      expect(find.text('收藏'), findsOneWidget);
    });

    /// 轨道标题。不用 find.text 断言 —— 卡片副行也显示分组名，
    /// 一个 'News' 能同时命中轨道标题和一堆副行。
    List<String> railTitles(WidgetTester t) =>
        t.widgetList<ChannelRail>(find.byType(ChannelRail))
            .map((r) => r.title)
            .toList();

    testWidgets('按分组铺轨道,频道多的排前面', (tester) async {
      await _pump(tester, body());
      final titles = railTitles(tester);
      // News 6 个 > Sports 4 个,News 应排在 Sports 之前。
      expect(titles.indexOf('News'), lessThan(titles.indexOf('Sports')));
    });

    testWidgets('频道太少的分组不单独占一行', (tester) async {
      await _pump(tester,
          body(channels: [..._many('News', 6), ..._many('Tiny', 2)]));
      final titles = railTitles(tester);
      expect(titles, contains('News'));
      expect(titles, isNot(contains('Tiny')));
    });

    testWidgets('最近与收藏为空时那两条轨道不占位', (tester) async {
      await _pump(tester, body(recent: [], favorites: []));
      expect(find.text('最近观看'), findsNothing);
      expect(find.text('收藏'), findsNothing);
    });

    testWidgets('窄屏 320 不溢出', (tester) async {
      await _pump(tester, body(), size: const Size(320, 640));
      _expectNoOverflow();
    });

    testWidgets('文字放大 1.3 倍不溢出', (tester) async {
      await _pump(tester, body(), textScale: 1.3);
      _expectNoOverflow();
    });

    testWidgets('遥控器输入下卡片更大 —— 十英尺观看距离', (tester) async {
      await _pump(tester, body(),
          size: const Size(1280, 720), input: InputMode.remote);
      _expectNoOverflow();
    });
  });
}
