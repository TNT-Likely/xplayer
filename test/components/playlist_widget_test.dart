import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/widgets/playlist_widget.dart';

final _now = DateTime(2026, 8, 14, 12, 0);

Playlist _pl({
  int id = 1,
  String name = '主源',
  String url = 'https://iptv-org.github.io/iptv/index.m3u',
  String? channels,
  DateTime? updatedAt,
}) =>
    Playlist(
      id: id,
      name: name,
      url: url,
      channels: channels,
      updatedAt: updatedAt,
    );

Future<void> _pump(
  WidgetTester tester,
  List<Playlist> playlists, {
  Size size = const Size(400, 700),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('zh')],
    home: Scaffold(
      body: PlaylistListWidget(
        playlists: playlists,
        clock: () => _now,
        onAdd: () {},
        onDelete: (_) async {},
        onUpdate: (_) async {},
        onLoadAll: () async {},
        onRefresh: (_, __) async {},
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('布局不溢出', () {
    // 这组是回归护栏:改造时用 ListTile 装两行 subtitle,真机上报
    // 「RenderFlex overflowed by 15 pixels on the bottom」。
    testWidgets('常规条目不溢出', (tester) async {
      await _pump(tester, [
        _pl(channels: '[{},{},{}]', updatedAt: _now.subtract(const Duration(minutes: 2))),
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('长名称 + 长地址不溢出', (tester) async {
      await _pump(tester, [
        _pl(
          name: '一个特别特别长的播放列表名称用来测试溢出情况到底会不会发生',
          url: 'https://example.com/very/long/path/that/keeps/going/'
              'and/going/playlist-with-a-really-long-name.m3u8?token=abcdef123456',
          channels: '[{},{}]',
          updatedAt: _now.subtract(const Duration(days: 400)),
        ),
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('窄屏(320)下不溢出', (tester) async {
      await _pump(
        tester,
        [_pl(channels: '[{}]', updatedAt: _now.subtract(const Duration(days: 9)))],
        size: const Size(320, 600),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('多条目滚动不溢出', (tester) async {
      await _pump(tester, [
        for (var i = 1; i <= 8; i++)
          _pl(id: i, name: '源 $i', channels: '[{},{}]',
              updatedAt: _now.subtract(Duration(days: i))),
      ]);
      expect(tester.takeException(), isNull);
    });
  });

  group('信息展示', () {
    testWidgets('不显示数据库主键 —— 那对用户没有任何意义', (tester) async {
      await _pump(tester, [_pl(id: 3, name: '主源')]);
      expect(find.text('主源'), findsOneWidget);
      expect(find.text('3: 主源'), findsNothing);
    });

    testWidgets('显示频道数与相对更新时间', (tester) async {
      await _pump(tester, [
        _pl(channels: '[{},{},{}]',
            updatedAt: _now.subtract(const Duration(days: 3))),
      ]);
      expect(find.textContaining('3 个频道'), findsOneWidget);
      expect(find.textContaining('3 天前'), findsOneWidget);
    });

    testWidgets('取不到频道数时不显示 0 —— 免得误导用户以为源是空的', (tester) async {
      await _pump(tester, [
        _pl(channels: null, updatedAt: _now.subtract(const Duration(hours: 2))),
      ]);
      expect(find.textContaining('0 个频道'), findsNothing);
      expect(find.textContaining('2 小时前'), findsOneWidget);
    });

    testWidgets('缓存格式异常时不崩,只是不显示计数', (tester) async {
      await _pump(tester, [_pl(channels: '{不是合法 json')]);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('个频道'), findsNothing);
    });

    testWidgets('从未更新时给明确说法,而不是留空', (tester) async {
      await _pump(tester, [_pl(updatedAt: null)]);
      expect(find.text('尚未更新'), findsOneWidget);
    });
  });

  group('空状态', () {
    testWidgets('没有播放列表时给空状态,文案直说不内置频道', (tester) async {
      await _pump(tester, []);
      expect(find.text('添加一个播放列表'), findsOneWidget);
      expect(find.textContaining('不内置频道'), findsOneWidget);
    });

    testWidgets('空状态不溢出', (tester) async {
      await _pump(tester, [], size: const Size(320, 480));
      expect(tester.takeException(), isNull);
    });
  });
}
