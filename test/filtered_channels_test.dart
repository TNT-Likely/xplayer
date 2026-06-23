import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/utils/channel_filter.dart';

Channel _ch(String id, String name, String group) => Channel(
      id: id,
      name: name,
      source: [
        Source(
          title: name,
          link: 'http://example/$id',
          groupTitle: group,
          attributes: const {},
          duration: 0,
        ),
      ],
    );

void main() {
  final sample = [
    _ch('CCTV1', 'CCTV1 综合', 'News'),
    _ch('HBO', 'HBO', 'Movies'),
    _ch('CCTV5', 'CCTV5 体育', 'Sports'),
  ];

  test('query 按名称/ID 模糊匹配(不区分大小写)', () {
    expect(
      filterChannels(sample, query: 'cctv').map((c) => c.id).toList(),
      ['CCTV1', 'CCTV5'],
    );
  });

  test('group 按 groupTitle 过滤', () {
    expect(
      filterChannels(sample, group: 'Sports').map((c) => c.id).toList(),
      ['CCTV5'],
    );
  });

  test('query + group 同时生效 (AND)', () {
    expect(
      filterChannels(sample, query: 'cctv', group: 'News').map((c) => c.id).toList(),
      ['CCTV1'],
    );
  });

  test('group 为 null / 空表示全部', () {
    expect(filterChannels(sample).length, 3);
    expect(filterChannels(sample, group: '').length, 3);
  });

  test('distinctGroups 去重且保持顺序', () {
    expect(distinctGroups(sample), ['News', 'Movies', 'Sports']);
  });
}
