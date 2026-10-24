import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/utils/epg_index.dart';

Programme _p(String channel, String start, String stop, String title) =>
    Programme(
      channel: channel,
      start: DateTime.parse(start),
      stop: DateTime.parse(stop),
      title: title,
    );

void main() {
  final now = DateTime.parse('2026-10-24 20:47:00');
  late EpgIndex index;

  setUp(() {
    index = EpgIndex.fromProgrammes([
      // 大小写混排:索引键统一小写
      _p('cctv-1', '2026-10-24 20:06:00', '2026-10-24 21:00:00', '晚间剧场'),
      _p('CCTV-1', '2026-10-24 21:00:00', '2026-10-24 21:32:00', '新闻夜线'),
      _p('cctv-1', '2026-10-24 19:00:00', '2026-10-24 19:30:00', '已结束的节目'),
      _p('cctv-5', '2026-10-24 19:45:00', '2026-10-24 21:05:00', '世预赛'),
    ]);
  });

  test('currentFor 命中当前节目(不区分大小写)', () {
    final p = index.currentFor('CCTV-1', now);
    expect(p, isNotNull);
    expect(p!.title, '晚间剧场');
  });

  test('currentFor 对无 EPG 频道返回 null', () {
    expect(index.currentFor('cctv-6', now), isNull);
  });

  test('nextFor 返回当前节目之后的下一档', () {
    final p = index.nextFor('cctv-1', now);
    expect(p, isNotNull);
    expect(p!.title, '新闻夜线');
  });

  test('nextFor 在节目间隙返回下一档', () {
    // 21:00 新闻夜线结束后、21:32 无下档 → next 为 null;
    // 但 20:53(还在晚间剧场)之后是新闻夜线
    final p = index.nextFor('cctv-1', DateTime.parse('2026-10-24 20:53:00'));
    expect(p, isNotNull);
    expect(p!.title, '新闻夜线');
  });

  test('progressOf 计算进度并夹取 0..1', () {
    final p = index.currentFor('cctv-5', now);
    // 19:45–21:05,20:47 时约 78%
    final progress = EpgIndex.progressOf(p, now)!;
    expect(progress, greaterThan(0.75));
    expect(progress, lessThan(0.8));
    // 已结束的节目 → 1.0
    final ended = index.currentFor('cctv-1', DateTime.parse('2026-10-24 19:15:00'));
    expect(EpgIndex.progressOf(ended, DateTime.parse('2026-10-24 19:15:00')),
        lessThan(1.0));
  });

  test('空索引安全', () {
    expect(EpgIndex.empty.currentFor('cctv-1', now), isNull);
    expect(EpgIndex.empty.nextFor('cctv-1', now), isNull);
  });
}
