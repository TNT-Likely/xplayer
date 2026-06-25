import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/utils/recent_util.dart';

Channel ch(String id) => Channel(id: id, name: id, source: const []);

void main() {
  test('新频道插入队首', () {
    final r = mergeRecent([ch('a'), ch('b')], ch('c'), max: 20);
    expect(r.map((e) => e.id).toList(), ['c', 'a', 'b']);
  });
  test('重复频道去重并置顶', () {
    final r = mergeRecent([ch('a'), ch('b'), ch('c')], ch('c'), max: 20);
    expect(r.map((e) => e.id).toList(), ['c', 'a', 'b']);
  });
  test('容量上限裁剪', () {
    final base = List.generate(20, (i) => ch('c$i'));
    final r = mergeRecent(base, ch('new'), max: 20);
    expect(r.length, 20);
    expect(r.first.id, 'new');
    expect(r.any((e) => e.id == 'c19'), false);
  });
}
