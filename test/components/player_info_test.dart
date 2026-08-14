import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/presentation/components/live_edge_badge.dart';
import 'package:xplayer/presentation/components/playback_failure.dart';
import 'package:xplayer/presentation/components/programme_progress.dart';

Future<void> _pump(WidgetTester t, Widget child) => t.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  group('LiveEdge', () {
    test('小抖动算贴边 —— 直播流本身有缓冲,几百毫秒就报「落后」会让人以为出问题', () {
      expect(const LiveEdge(Duration(seconds: 2)).isAtEdge, isTrue);
      expect(const LiveEdge(Duration(seconds: 5)).isAtEdge, isTrue);
      expect(const LiveEdge(Duration(seconds: 6)).isAtEdge, isFalse);
    });

    test('atEdge 构造即零偏移', () {
      expect(const LiveEdge.atEdge().behind, Duration.zero);
      expect(const LiveEdge.atEdge().isAtEdge, isTrue);
    });

    test('落后时长格式化为 m:ss', () {
      expect(LiveEdgeBadge.formatBehind(const Duration(seconds: 74)), '1:14');
      expect(LiveEdgeBadge.formatBehind(const Duration(seconds: 9)), '0:09');
      expect(LiveEdgeBadge.formatBehind(const Duration(minutes: 12)), '12:00');
    });
  });

  group('LiveEdgeBadge', () {
    testWidgets('贴边时只显示「直播」,不给按钮 —— 常态不需要操作', (tester) async {
      await _pump(
          tester,
          LiveEdgeBadge(
              edge: const LiveEdge.atEdge(), onSeekToLive: () {}));
      expect(find.text('直播'), findsOneWidget);
      expect(find.text('回到直播'), findsNothing);
    });

    testWidgets('落后时显示时长并给「回到直播」', (tester) async {
      await _pump(
        tester,
        LiveEdgeBadge(
            edge: const LiveEdge(Duration(seconds: 134)),
            onSeekToLive: () {}),
      );
      expect(find.text('落后 2:14'), findsOneWidget);
      expect(find.text('回到直播'), findsOneWidget);
    });

    testWidgets('点「回到直播」触发回调', (tester) async {
      var fired = false;
      await _pump(
        tester,
        LiveEdgeBadge(
            edge: const LiveEdge(Duration(minutes: 3)),
            onSeekToLive: () => fired = true),
      );
      await tester.tap(find.text('回到直播'));
      expect(fired, isTrue);
    });

    testWidgets('没给回调时不显示按钮', (tester) async {
      await _pump(
          tester, const LiveEdgeBadge(edge: LiveEdge(Duration(minutes: 3))));
      expect(find.text('回到直播'), findsNothing);
    });
  });

  group('NowPlaying 进度计算', () {
    final start = DateTime(2026, 8, 14, 19, 0);
    final end = DateTime(2026, 8, 14, 19, 30);
    final p = NowPlaying(title: '新闻联播', start: start, end: end);

    test('进度按真实时长算', () {
      expect(p.progressAt(start), 0);
      expect(p.progressAt(DateTime(2026, 8, 14, 19, 15)), closeTo(0.5, 0.01));
      expect(p.progressAt(end), 1);
    });

    test('越界被夹住,不产出负数或大于 1', () {
      expect(p.progressAt(start.subtract(const Duration(hours: 1))), 0);
      expect(p.progressAt(end.add(const Duration(hours: 1))), 1);
    });

    test('时长非法时返回 0,不产出 NaN 把布局搞崩', () {
      final bad = NowPlaying(title: 'x', start: start, end: start);
      expect(bad.progressAt(start), 0);
      expect(bad.progressAt(start).isNaN, isFalse);
    });

    test('剩余时长不为负', () {
      expect(p.remainingAt(DateTime(2026, 8, 14, 19, 12)),
          const Duration(minutes: 18));
      expect(p.remainingAt(end.add(const Duration(hours: 1))), Duration.zero);
    });
  });

  group('ProgrammeProgress', () {
    final now = DateTime(2026, 8, 14, 19, 12);
    final p = NowPlaying(
      title: '新闻联播',
      start: DateTime(2026, 8, 14, 19, 0),
      end: DateTime(2026, 8, 14, 19, 30),
    );

    testWidgets('显示节目名、起止时间与剩余', (tester) async {
      await _pump(tester, ProgrammeProgress(programme: p, now: now));
      expect(find.text('新闻联播'), findsOneWidget);
      expect(find.text('19:00 – 19:30'), findsOneWidget);
      expect(find.text('还剩 18 分钟'), findsOneWidget);
    });

    testWidgets('没有 EPG 时整块隐藏 —— 那是多数情况,不该看起来像出错',
        (tester) async {
      await _pump(tester, ProgrammeProgress(programme: null, now: now));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('进度条不可交互 —— 直播拖不了,做成可拖会让用户以为能回看',
        (tester) async {
      await _pump(tester, ProgrammeProgress(programme: p, now: now));
      // 限定在组件内部找 —— MaterialApp/Scaffold 内部自己也用 IgnorePointer。
      expect(
        find.descendant(
          of: find.byType(ProgrammeProgress),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });

    test('剩余时长文案分档', () {
      expect(ProgrammeProgress.formatRemaining(const Duration(seconds: 30)),
          '即将结束');
      expect(ProgrammeProgress.formatRemaining(const Duration(minutes: 18)),
          '还剩 18 分钟');
      expect(ProgrammeProgress.formatRemaining(const Duration(hours: 2)),
          '还剩 2 小时');
      expect(
          ProgrammeProgress.formatRemaining(
              const Duration(hours: 1, minutes: 20)),
          '还剩 1 小时 20 分');
    });
  });

  group('ReconnectingView', () {
    testWidgets('把「第几次尝试」摆出来 —— 用户据此判断该等还是该走',
        (tester) async {
      await _pump(
        tester,
        const ReconnectingView(
            channelName: 'CCTV-1 综合', attempt: 2, maxAttempts: 3),
      );
      expect(find.textContaining('正在重连 CCTV-1 综合'), findsOneWidget);
      expect(find.text('第 2 次尝试 · 共 3 次'), findsOneWidget);
    });

    testWidgets('给了回调才显示对应出口', (tester) async {
      await _pump(
        tester,
        ReconnectingView(
          channelName: 'X',
          attempt: 1,
          maxAttempts: 3,
          onTryAnotherSource: () {},
        ),
      );
      expect(find.text('换个源'), findsOneWidget);
      expect(find.text('返回列表'), findsNothing);
    });
  });

  group('PlaybackFailedView', () {
    testWidgets('说清原因与可做的事,不含糊', (tester) async {
      await _pump(
        tester,
        PlaybackFailedView(
          attempts: 3,
          onRetry: () {},
          onMarkDead: () {},
          onDiagnostics: () {},
        ),
      );
      expect(find.text('这条源连不上'), findsOneWidget);
      expect(find.textContaining('重试 3 次均超时'), findsOneWidget);
      expect(find.textContaining('可能已失效'), findsOneWidget);
      expect(find.text('再试一次'), findsOneWidget);
      expect(find.text('标记为失效'), findsOneWidget);
      expect(find.text('查看诊断'), findsOneWidget);
    });

    testWidgets('可传入更具体的原因覆盖默认文案', (tester) async {
      await _pump(
        tester,
        const PlaybackFailedView(attempts: 3, reason: 'DNS 解析失败'),
      );
      expect(find.text('DNS 解析失败'), findsOneWidget);
      expect(find.textContaining('重试 3 次'), findsNothing);
    });

    testWidgets('「标记为失效」触发回调 —— 喂回健康度系统', (tester) async {
      var marked = false;
      await _pump(
        tester,
        PlaybackFailedView(attempts: 3, onMarkDead: () => marked = true),
      );
      await tester.tap(find.text('标记为失效'));
      expect(marked, isTrue);
    });
  });
}
