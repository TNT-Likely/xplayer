import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

final now = DateTime(2026, 10, 25, 20, 42);
final programme = XpProgramme(
    title: '向野而生',
    start: DateTime(2026, 10, 25, 20),
    end: DateTime(2026, 10, 25, 21));
final channel = XpChannelData(
    id: '9', name: 'CCTV-9 纪录', logoLabel: 'CCTV9', programme: programme);

Widget host(Widget child,
    {XpDevice device = XpDevice.phone,
    double textScale = 1,
    bool reduceMotion = false}) {
  final data = XpThemeData(device: device, reduceMotion: reduceMotion);
  return XpTheme(
      data: data,
      child: MaterialApp(
          theme: data.materialTheme(),
          home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                  body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16), child: child)))));
}

void main() {
  test('节目区间按绝对时间计算，结束时刻不再标记当前', () {
    expect(programme.progressAt(now), closeTo(.7, .0001));
    expect(programme.isCurrent(programme.end), isFalse);
    expect(
        programme
            .progressAt(programme.start.subtract(const Duration(hours: 1))),
        0);
    final invalid =
        XpProgramme(title: '坏数据', start: programme.end, end: programme.start);
    expect(invalid.progressAt(now), isNull);
    expect(invalid.isCurrent(now), isFalse);
    final crossMidnight = XpProgramme(
        title: '跨午夜',
        start: DateTime.utc(2026, 10, 25, 23, 30),
        end: DateTime.utc(2026, 10, 26, 0, 30));
    expect(crossMidnight.progressAt(DateTime.utc(2026, 10, 26)), .5);
  });

  testWidgets('错误输入保留原值，搜索清除通知宿主', (tester) async {
    final address = TextEditingController(text: 'file:///guide.xml');
    final search = TextEditingController(text: 'CCTV9');
    addTearDown(address.dispose);
    addTearDown(search.dispose);
    String? changed;
    await tester.pumpWidget(host(Column(children: [
      XpTextField(
          controller: address, label: 'XMLTV 地址', error: '需要 http 或 https 地址'),
      XpSearchField(controller: search, onChanged: (value) => changed = value),
    ])));
    expect(address.text, 'file:///guide.xml');
    expect(find.text('需要 http 或 https 地址'), findsOneWidget);
    await tester.tap(find.byTooltip('清除搜索'));
    expect(search.text, '');
    expect(changed, '');
  });

  testWidgets('TV 方向键移动焦点，确认键触发当前操作', (tester) async {
    final first = FocusNode(), second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var selected = '';
    await tester.pumpWidget(host(
        Row(children: [
          XpButton(
              label: '上一个',
              focusNode: first,
              onPressed: () => selected = 'first'),
          XpButton(
              label: '下一个',
              focusNode: second,
              onPressed: () => selected = 'second'),
        ]),
        device: XpDevice.tv));
    first.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(second.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, 'second');
  });

  testWidgets('减少动态时保留忙碌语义并停止加载动画', (tester) async {
    await tester.pumpWidget(host(
        XpButton(label: '获取节目单', loading: true, onPressed: () {}),
        reduceMotion: true));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('获取节目单，处理中'), findsOneWidget);
  });

  testWidgets('无 EPG 不泄漏节目或进度，收藏不触发播放', (tester) async {
    var plays = 0;
    bool? favourite;
    await tester.pumpWidget(host(XpChannelCard(
        channel: channel,
        now: now,
        epgStatus: XpEpgStatus.error,
        onPlay: () => plays++,
        onFavouriteChanged: (v) => favourite = v)));
    await tester.pumpAndSettle();
    expect(find.text('暂无节目单'), findsOneWidget);
    expect(find.text('向野而生'), findsNothing);
    expect(find.byType(XpProgress), findsNothing);
    await tester.tap(find.byType(XpFavouriteButton));
    expect(favourite, isTrue);
    expect(plays, 0);
    await tester.tap(find.bySemanticsLabel('观看 CCTV-9 纪录'));
    expect(plays, 1);
  });

  testWidgets('加载、禁用阻止重复回调，键盘确认可激活普通按钮', (tester) async {
    var calls = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
        host(XpButton(label: '重试', loading: true, onPressed: () => calls++)));
    await tester.tap(find.byType(TextButton));
    expect(calls, 0);
    await tester.pumpWidget(
        host(XpButton(label: '重试', focusNode: node, onPressed: () => calls++)));
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(calls, 1);
  });

  testWidgets('节目单失败与首次加载都保留独立的选台入口', (tester) async {
    var watches = 0;
    for (final status in [
      XpEpgStatus.error,
      XpEpgStatus.loading,
      XpEpgStatus.unconfigured
    ]) {
      await tester.pumpWidget(
          host(XpEpgStateView(status: status, onWatch: () => watches++)));
      await tester.pump();
      await tester.tap(find.text('浏览频道'));
    }
    expect(watches, 3);
  });

  testWidgets('缓存覆盖结束后自动降级为过期，子时间轴也移除当前标记', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(XpEpgStateView(
      status: XpEpgStatus.errorWithCache,
      now: now,
      coverageEnd: now.subtract(const Duration(minutes: 1)),
      onWatch: () {},
      child: XpEpgTimeline(rows: [
        XpEpgRowData(channel: channel, programmes: [programme])
      ], start: programme.start, end: programme.end, now: now),
    )));
    await tester.pumpAndSettle();
    expect(find.text('这份节目单已经过期'), findsOneWidget);
    expect(find.text('正在播出'), findsNothing);
    expect(find.text('缓存节目'), findsOneWidget);
    expect(find.bySemanticsLabel('当前时间 20:42'), findsNothing);
    semantics.dispose();
  });

  testWidgets('部分缺失保留频道身份和播放回调', (tester) async {
    String? selected;
    await tester.pumpWidget(host(XpEpgTimeline(
        rows: [XpEpgRowData(channel: channel, programmes: const [])],
        start: programme.start,
        end: programme.end,
        now: now,
        onWatchChannel: (c) => selected = c.id)));
    await tester.pumpAndSettle();
    expect(find.text('暂无节目信息'), findsOneWidget);
    await tester.tap(find.text('观看频道'));
    expect(selected, '9');
  });

  testWidgets('播放器能力为空时不展示画质、音轨或全屏的虚假操作', (tester) async {
    await tester.pumpWidget(
        host(XpPlayerControls(paused: false, onTogglePause: () {})));
    expect(find.text('4K'), findsNothing);
    expect(find.text('国语'), findsNothing);
    expect(find.byTooltip('全屏播放'), findsNothing);
    expect(find.byTooltip('暂停播放'), findsOneWidget);
  });

  testWidgets('未连接遥控器禁止发送按键', (tester) async {
    var sent = 0;
    await tester.pumpWidget(
        host(XpRemotePad(connected: false, onCommand: (_) => sent++)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('确认选择'));
    expect(sent, 0);
    await tester.pumpWidget(
        host(XpRemotePad(connected: true, onCommand: (_) => sent++)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('确认选择'));
    expect(sent, 1);
  });

  testWidgets('同步取消不提交；确认只提交存在的勾选字段', (tester) async {
    var cancelled = 0;
    Set<String>? applied;
    await tester.pumpWidget(host(XpSyncDiffPanel(
      fields: const [
        XpSyncField(id: 'list', label: '列表', local: '3', remote: '4')
      ],
      selectedIds: const {'list', 'stale-id'},
      onSelectionChanged: (_) {},
      onApply: (ids) => applied = ids,
      onCancel: () => cancelled++,
    )));
    await tester.tap(find.text('取消，保留当前配置'));
    expect(cancelled, 1);
    expect(applied, isNull);
    await tester.tap(find.text('应用所选项目'));
    expect(applied, {'list'});
  });

  testWidgets('长文本与 2 倍字号在四端密度下无布局溢出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final device in XpDevice.values) {
      await tester.pumpWidget(host(
          Column(children: [
            XpButton(label: '这是一个需要完整显示的操作标签', onPressed: () {}),
            XpToggleTile(
                title: '一段特别长的设置说明，放大字体之后仍然可以读取',
                description: '附加说明会自然换行。',
                value: true,
                onChanged: (_) {}),
            XpChannelCard(channel: channel, now: now, onPlay: () {}),
            const XpEmptyState(
                title: '这一份节目单暂时获取失败', description: '错误解释可以换行，核心操作仍然可以到达。'),
            XpEpgTimeline(rows: [
              XpEpgRowData(channel: channel, programmes: [programme])
            ], start: programme.start, end: programme.end, now: now),
          ]),
          device: device,
          textScale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: device.name);
    }
  });
}
