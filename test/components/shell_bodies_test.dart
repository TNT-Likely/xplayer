import 'package:adaptive_shell/adaptive_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/components/channel_rail.dart';
import 'package:xplayer/presentation/components/expanded_home_body.dart';
import 'package:xplayer/presentation/components/ten_foot_home_body.dart';
import 'package:xplayer/providers/media_provider.dart';

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
  required Size size,
  required InputMode input,
  double textScale = 1.0,
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

final _channels = [..._many('News', 8), ..._many('Sports', 5)];

void main() {
  group('ExpandedHomeBody 宽屏', () {
    Widget body() => ExpandedHomeBody(
          channels: _channels,
          recentChannels: _many('News', 3),
          favoriteChannels: _many('Sports', 3),
        );

    testWidgets('有常驻侧栏 —— 宽屏不必靠弹窗遮挡内容才能选分组', (tester) async {
      await _pump(tester, body(),
          size: const Size(1280, 800), input: InputMode.pointer);
      expect(find.text('分组'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
    });

    testWidgets('侧栏列出分组与计数', (tester) async {
      await _pump(tester, body(),
          size: const Size(1280, 800), input: InputMode.pointer);
      expect(find.text('News'), findsWidgets);
      expect(find.text('8'), findsWidgets);
    });

    testWidgets('点分组只换主区内容,不做页面跳转', (tester) async {
      await _pump(tester, body(),
          size: const Size(1280, 800), input: InputMode.pointer);
      // 默认浏览态:多条轨道
      expect(
          tester.widgetList<ChannelRail>(find.byType(ChannelRail)).length,
          greaterThan(1));

      await tester.tap(find.text('Sports').first);
      await tester.pump();

      // 选中后只剩那一条轨道,且仍在同一个 body 里(没有新路由)
      final rails =
          tester.widgetList<ChannelRail>(find.byType(ChannelRail)).toList();
      expect(rails, hasLength(1));
      expect(rails.first.title, 'Sports');
      expect(find.byType(ExpandedHomeBody), findsOneWidget);
    });

    testWidgets('各档宽度不溢出', (tester) async {
      for (final w in [1000.0, 1280.0, 1920.0, 2560.0]) {
        await _pump(tester, body(),
            size: Size(w, 800), input: InputMode.pointer);
        _expectNoOverflow();
      }
    });

    testWidgets('文字放大 1.3 倍不溢出', (tester) async {
      await _pump(tester, body(),
          size: const Size(1280, 800),
          input: InputMode.pointer,
          textScale: 1.3);
      _expectNoOverflow();
    });
  });

  group('TenFootHomeBody 电视', () {
    Widget body() => TenFootHomeBody(
          channels: _channels,
          recentChannels: _many('News', 4),
          favoriteChannels: _many('Sports', 4),
        );

    testWidgets('四周留过扫描安全边距 —— 老电视会切掉画面边缘', (tester) async {
      const size = Size(1920, 1080);
      await _pump(tester, body(), size: size, input: InputMode.remote);
      final pad = tester.widget<Padding>(find
          .descendant(
              of: find.byType(TenFootHomeBody), matching: find.byType(Padding))
          .first);
      final insets = pad.padding.resolve(TextDirection.ltr);
      expect(insets.left, closeTo(size.width * 0.05, 0.5));
      expect(insets.top, closeTo(size.height * 0.05, 0.5));
    });

    testWidgets('频道太少的分组不占一行 —— 电视上每行更贵', (tester) async {
      await _pump(
        tester,
        TenFootHomeBody(
          channels: [..._many('News', 8), ..._many('Few', 3)],
          recentChannels: const [],
          favoriteChannels: const [],
        ),
        size: const Size(1920, 1080),
        input: InputMode.remote,
      );
      final titles = tester
          .widgetList<ChannelRail>(find.byType(ChannelRail))
          .map((r) => r.title)
          .toList();
      expect(titles, contains('News'));
      // 手机端阈值是 3，电视端是 4，所以 3 个的分组在这里应被挡掉。
      expect(titles, isNot(contains('Few')));
    });

    testWidgets('常见电视分辨率下不溢出', (tester) async {
      for (final s in [
        const Size(1280, 720),
        const Size(1920, 1080),
        const Size(3840, 2160),
      ]) {
        await _pump(tester, body(), size: s, input: InputMode.remote);
        _expectNoOverflow();
      }
    });
  });

  group('ChannelZapOsd 切台浮层', () {
    Future<void> osd(WidgetTester tester, {int? number, String? prog}) => _pump(
          tester,
          Center(
            child: ChannelZapOsd(
              channel: _ch('CCTV-5 体育'),
              number: number,
              programme: prog,
            ),
          ),
          size: const Size(1920, 1080),
          input: InputMode.remote,
        );

    testWidgets('频道号补零到三位 —— 连按数字时宽度不跳动', (tester) async {
      await osd(tester, number: 5);
      expect(find.text('005'), findsOneWidget);
    });

    testWidgets('三位数不额外补零', (tester) async {
      await osd(tester, number: 128);
      expect(find.text('128'), findsOneWidget);
    });

    testWidgets('没有节目单时整行省略,不留空', (tester) async {
      await osd(tester, number: 5);
      expect(find.text('CCTV-5 体育'), findsOneWidget);
      _expectNoOverflow();
    });

    testWidgets('有节目单时显示', (tester) async {
      await osd(tester, number: 5, prog: '赛事直播 · 中超');
      expect(find.text('赛事直播 · 中超'), findsOneWidget);
    });
  });
}
