import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/utils/epg_metrics.dart';

Programme _p(String ch, DateTime s, DateTime e, [String t = 'x']) =>
    Programme(channel: ch, start: s, stop: e, title: t);
Channel _c(String id) => Channel(id: id, name: id, source: const []);

void main() {
  final base = DateTime(2026, 6, 24, 0, 0); // 本地 00:00

  test('xForTime / contentWidth 按分钟×像素', () {
    final m = EpgMetrics(
        windowStart: base, windowEnd: base.add(const Duration(hours: 2)));
    expect(m.pxPerMinute, 4);
    expect(m.xForTime(base), 0);
    expect(m.xForTime(base.add(const Duration(minutes: 30))), 120);
    expect(m.contentWidth, 2 * 60 * 4);
  });

  test('widthForRange 不小于最小宽度', () {
    final m = EpgMetrics(windowStart: base, windowEnd: base);
    expect(m.widthForRange(base, base.add(const Duration(minutes: 1))), 48);
    expect(m.widthForRange(base, base.add(const Duration(minutes: 30))), 120);
  });

  test('fromProgrammes 把窗口撑到节目跨度(并含当天)', () {
    final progs = [
      _p('a', base.subtract(const Duration(hours: 3)),
          base.subtract(const Duration(hours: 2))),
      _p('a', base.add(const Duration(hours: 25)),
          base.add(const Duration(hours: 26))),
    ];
    final m = EpgMetrics.fromProgrammes(progs,
        now: base.add(const Duration(hours: 10)));
    expect(
        m.windowStart
            .isAtSameMomentAs(base.subtract(const Duration(hours: 3))),
        true);
    expect(m.windowEnd.isAtSameMomentAs(base.add(const Duration(hours: 26))),
        true);
  });

  test('channelsWithEpg 按 id 大小写不敏感过滤', () {
    final chans = [_c('CCTV-1'), _c('CCTV-5'), _c('NOEPG')];
    final progs = [_p('cctv-1', base, base.add(const Duration(hours: 1)))];
    final r = channelsWithEpg(chans, progs);
    expect(r.map((c) => c.id), ['CCTV-1']);
  });

  test('programmesFor 过滤并按 start 升序', () {
    final progs = [
      _p('a', base.add(const Duration(hours: 2)),
          base.add(const Duration(hours: 3)), 'late'),
      _p('a', base, base.add(const Duration(hours: 1)), 'early'),
      _p('b', base, base.add(const Duration(hours: 1)), 'other'),
    ];
    final r = programmesFor(progs, 'A');
    expect(r.map((p) => p.title), ['early', 'late']);
  });

  test('isLive: start<=now<stop', () {
    final now = base.add(const Duration(hours: 10));
    expect(
        isLive(
            _p('a', now.subtract(const Duration(minutes: 5)),
                now.add(const Duration(minutes: 5))),
            now),
        true);
    expect(
        isLive(
            _p('a', now.add(const Duration(minutes: 1)),
                now.add(const Duration(minutes: 5))),
            now),
        false);
    expect(
        isLive(
            _p('a', now.subtract(const Duration(minutes: 10)),
                now.subtract(const Duration(minutes: 1))),
            now),
        false);
  });

  test('upcomingProgrammes: now 起的当前+后续, 升序, 过滤已结束, 限 count', () {
    final now0 = base.add(const Duration(hours: 20)); // 20:00
    final progs = [
      _p('c', now0.subtract(const Duration(hours: 2)),
          now0.subtract(const Duration(hours: 1)), '过去'),
      _p('c', now0.subtract(const Duration(minutes: 30)),
          now0.add(const Duration(minutes: 30)), '正在'),
      _p('c', now0.add(const Duration(minutes: 30)),
          now0.add(const Duration(hours: 1)), '接着1'),
      _p('c', now0.add(const Duration(hours: 1)),
          now0.add(const Duration(hours: 2)), '接着2'),
      _p('X', now0, now0.add(const Duration(hours: 1)), '别的台'),
    ];
    final r = upcomingProgrammes(progs, 'c', now0, count: 2);
    expect(r.map((p) => p.title).toList(), ['正在', '接着1']);
  });
}
