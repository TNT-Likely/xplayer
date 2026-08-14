import 'package:epg_xmltv/epg_xmltv.dart';
import 'package:test/test.dart';

Programme _p(String channel, String title, DateTime start, DateTime stop) =>
    Programme(channel: channel, title: title, start: start, stop: stop);

void main() {
  final base = DateTime(2026, 8, 14, 19, 0);

  final programmes = [
    _p('CCTV1', '新闻 30 分', base.subtract(const Duration(minutes: 30)), base),
    _p('CCTV1', '新闻联播', base, base.add(const Duration(minutes: 30))),
    _p('CCTV1', '焦点访谈', base.add(const Duration(minutes: 30)),
        base.add(const Duration(minutes: 45))),
    _p('CCTV5', '体育世界', base, base.add(const Duration(hours: 1))),
  ];

  group('findProgramme 按频道检索', () {
    test('只返回该频道的节目', () {
      final r = PlaylistUtil.findProgramme(programmes, 'CCTV1');
      expect(r, hasLength(3));
      expect(r.every((p) => p.channel == 'CCTV1'), isTrue);
    });

    test('频道名匹配不区分大小写 —— 不同源的大小写习惯不一致', () {
      expect(PlaylistUtil.findProgramme(programmes, 'cctv1'), hasLength(3));
      expect(PlaylistUtil.findProgramme(programmes, 'CcTv1'), hasLength(3));
    });

    test('没有节目单的频道返回空,不抛异常 —— 这是 IPTV 里的多数情况', () {
      expect(PlaylistUtil.findProgramme(programmes, 'UNKNOWN'), isEmpty);
    });
  });

  group('当前 / 下一个节目', () {
    test('播到一半时取到当前与下一个', () {
      final (idx, cur, next) = PlaylistUtil.findCurrentAndNextProgramme(
          programmes, 'CCTV1',
          base.add(const Duration(minutes: 10)));
      expect(cur?.title, '新闻联播');
      expect(next?.title, '焦点访谈');
      expect(idx, isNonNegative);
    });

    test('最后一个节目播放时没有下一个', () {
      final (_, cur, next) = PlaylistUtil.findCurrentAndNextProgramme(
          programmes, 'CCTV1',
          base.add(const Duration(minutes: 40)));
      expect(cur?.title, '焦点访谈');
      expect(next, isNull);
    });

    test('时间落在所有节目之外时当前为空', () {
      final (idx, cur, _) = PlaylistUtil.findCurrentAndNextProgramme(
          programmes, 'CCTV1',
          base.add(const Duration(days: 1)));
      expect(cur, isNull);
      expect(idx, -1);
    });

    test('频道为 null 时安全返回,不崩', () {
      final (idx, cur, next) =
          PlaylistUtil.findCurrentAndNextProgramme(programmes, null);
      expect(idx, -1);
      expect(cur, isNull);
      expect(next, isNull);
    });

    test('边界:恰好在节目起点算作正在播', () {
      final (_, cur, __) = PlaylistUtil.findCurrentAndNextProgramme(
          programmes, 'CCTV5',
          base.add(const Duration(seconds: 1)));
      expect(cur?.title, '体育世界');
    });
  });

  group('XMLTV 时间解析', () {
    test('解析带时区偏移的标准格式', () {
      final t = PlaylistUtil.parseCustomDateTime('20260814190000 +0800');
      expect(t.year, 2026);
      expect(t.month, 8);
      expect(t.day, 14);
    });

    test('解析不带偏移的格式', () {
      final t = PlaylistUtil.parseCustomDateTime('20260814190000');
      expect(t.year, 2026);
      expect(t.hour, 19);
    });

    test('非法输入不抛异常 —— 一条坏记录不该让整份节目单解析失败', () {
      expect(() => PlaylistUtil.parseCustomDateTime('乱七八糟'), returnsNormally);
      expect(() => PlaylistUtil.parseCustomDateTime(''), returnsNormally);
    });
  });
}
