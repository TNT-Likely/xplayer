import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/components/channel_plate.dart';
import 'package:xplayer/services/source_health_probe.dart';

Channel _ch(String id, {String link = 'http://ok/x.m3u8'}) => Channel(
      id: id,
      name: id,
      source: [
        Source(
          title: id,
          link: link,
          groupTitle: 'News',
          attributes: const {},
          duration: -1,
        )
      ],
    );

void main() {
  late DateTime now;
  late List<Uri> probed;

  setUp(() {
    now = DateTime(2026, 8, 14, 12);
    probed = [];
  });

  SourceHealthProbe make({
    required Future<bool> Function(Uri, Duration) reach,
    Duration ttl = const Duration(hours: 6),
    int concurrency = 6,
  }) =>
      SourceHealthProbe(
        now: () => now,
        reach: (u, t) {
          probed.add(u);
          return reach(u, t);
        },
        ttl: ttl,
        concurrency: concurrency,
      );

  group('基本探测', () {
    test('可达 → ok', () async {
      final p = make(reach: (_, __) async => true);
      await p.probeAll([_ch('A')]);
      expect(p.healthOf(_ch('A')), SourceHealth.ok);
    });

    test('不可达 → dead', () async {
      final p = make(reach: (_, __) async => false);
      await p.probeAll([_ch('A')]);
      expect(p.healthOf(_ch('A')), SourceHealth.dead);
    });

    test('探测抛异常也当 dead,不让一条坏源把整轮拖崩', () async {
      final p = make(reach: (_, __) async => throw StateError('boom'));
      await p.probeAll([_ch('A')]);
      expect(p.healthOf(_ch('A')), SourceHealth.dead);
    });

    test('地址为空或解析不了时直接判 dead,不发请求', () async {
      final p = make(reach: (_, __) async => true);
      await p.probeAll([_ch('A', link: ''), _ch('B', link: '不是URL')]);
      expect(p.healthOf(_ch('A')), SourceHealth.dead);
      expect(p.healthOf(_ch('B')), SourceHealth.dead);
      expect(probed, isEmpty, reason: '无效地址不该浪费一次网络请求');
    });
  });

  group('未探测 = 不标注', () {
    test('没探过返回 unknown —— 卡片据此不显示任何标记', () {
      final p = make(reach: (_, __) async => true);
      expect(p.healthOf(_ch('never')), SourceHealth.unknown);
    });

    test('结果过期后退回 unknown,而不是继续显示旧状态', () async {
      final p = make(reach: (_, __) async => false, ttl: const Duration(hours: 1));
      await p.probeAll([_ch('A')]);
      expect(p.healthOf(_ch('A')), SourceHealth.dead);

      now = now.add(const Duration(hours: 2));
      expect(p.healthOf(_ch('A')), SourceHealth.unknown);
    });
  });

  group('TTL 与去重', () {
    test('有效期内不重复探测', () async {
      final p = make(reach: (_, __) async => true);
      await p.probeAll([_ch('A')]);
      expect(probed, hasLength(1));

      final n = await p.probeAll([_ch('A')]);
      expect(n, 0, reason: '有效结果不该重复发请求');
      expect(probed, hasLength(1));
    });

    test('过期后会重新探测', () async {
      final p = make(reach: (_, __) async => true, ttl: const Duration(hours: 1));
      await p.probeAll([_ch('A')]);
      now = now.add(const Duration(hours: 2));
      final n = await p.probeAll([_ch('A')]);
      expect(n, 1);
      expect(probed, hasLength(2));
    });

    test('一批里只探没探过的那些', () async {
      final p = make(reach: (_, __) async => true);
      await p.probeAll([_ch('A')]);
      probed.clear();

      final n = await p.probeAll([_ch('A'), _ch('B'), _ch('C')]);
      expect(n, 2);
      expect(probed, hasLength(2));
    });
  });

  group('并发受控 —— 不能挤占播放本身的带宽', () {
    test('同时在飞的请求数不超过 concurrency', () async {
      var inFlight = 0;
      var peak = 0;
      final p = make(
        concurrency: 3,
        reach: (_, __) async {
          inFlight++;
          if (inFlight > peak) peak = inFlight;
          await Future<void>.delayed(const Duration(milliseconds: 1));
          inFlight--;
          return true;
        },
      );
      await p.probeAll([for (var i = 0; i < 12; i++) _ch('C$i')]);
      expect(peak, lessThanOrEqualTo(3));
    });
  });

  group('手动标记', () {
    test('用户在失败界面点「标记为失效」后立刻生效', () {
      final p = make(reach: (_, __) async => true);
      p.mark(_ch('A'), SourceHealth.dead);
      expect(p.healthOf(_ch('A')), SourceHealth.dead);
    });

    test('deadCount 统计失效条数,供抽屉显示', () async {
      final p = make(reach: (_, __) async => false);
      await p.probeAll([_ch('A'), _ch('B'), _ch('C')]);
      expect(p.deadCount, 3);
    });

    test('clear 清空全部结果', () async {
      final p = make(reach: (_, __) async => false);
      await p.probeAll([_ch('A')]);
      p.clear();
      expect(p.healthOf(_ch('A')), SourceHealth.unknown);
      expect(p.deadCount, 0);
    });
  });
}
