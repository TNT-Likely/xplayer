import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/utils/import_report.dart';

Source _src({String group = 'News', String link = 'http://a/x.m3u8'}) => Source(
      title: 't',
      link: link,
      groupTitle: group,
      attributes: const {},
      duration: -1,
    );

Channel _ch({
  String id = 'ID',
  String name = 'Name',
  String? quality,
  String? logo,
  List<Source>? sources,
}) =>
    Channel(
      id: id,
      name: name,
      quality: quality,
      logo: logo,
      source: sources ?? [_src()],
    );

void main() {
  group('analyzeChannels', () {
    test('空列表:各项归零,且算作干净', () {
      final r = analyzeChannels([]);
      expect(r.total, 0);
      expect(r.missingName, 0);
      expect(r.uncategorized, 0);
      expect(r.isClean, isTrue);
      expect(r.needsAttention, 0);
    });

    test('统计总数', () {
      expect(analyzeChannels([_ch(), _ch(), _ch()]).total, 3);
    });

    test('名字为空计入 missingName —— 这些只能回落到地址显示', () {
      final r = analyzeChannels([_ch(name: ''), _ch(name: '  '), _ch()]);
      expect(r.missingName, 2);
    });

    test('无分组标签计入 uncategorized', () {
      final r = analyzeChannels([
        _ch(sources: [_src(group: '')]),
        _ch(sources: [_src(group: 'Undefined')]),
        _ch(sources: [_src(group: 'News')]),
      ]);
      // 空串与 Undefined 都不产生标签,故两条都是未分类。
      expect(r.uncategorized, 2);
    });

    test('多 source 视为合并,merged 记录被并掉的条数', () {
      final r = analyzeChannels([
        _ch(sources: [_src(), _src(), _src()]), // 3 条并成 1 → 并掉 2
        _ch(sources: [_src(), _src()]), // 并掉 1
        _ch(), // 单条,不计
      ]);
      expect(r.merged, 3);
    });

    test('清晰度与台标分别统计', () {
      final r = analyzeChannels([
        _ch(quality: 'HD', logo: 'http://l/1.png'),
        _ch(quality: 'SD'),
        _ch(logo: 'http://l/2.png'),
        _ch(logo: '   '), // 空白 logo 不算
        _ch(),
      ]);
      expect(r.withQuality, 2);
      expect(r.withLogo, 2);
    });

    test('EPG 匹配数由调用方传入,不传记 0', () {
      expect(analyzeChannels([_ch()]).withEpg, 0);
      expect(analyzeChannels([_ch()], epgMatched: 412).withEpg, 412);
    });

    test('有需关注条目时 isClean 为假,needsAttention 是缺名与未分类之和', () {
      final r = analyzeChannels([
        _ch(name: ''),
        _ch(sources: [_src(group: '')]),
        _ch(),
      ]);
      expect(r.isClean, isFalse);
      expect(r.needsAttention, 2);
    });

    test('全部正常时 isClean 为真', () {
      final r = analyzeChannels([_ch(), _ch()]);
      expect(r.isClean, isTrue);
    });
  });
}
