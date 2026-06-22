import 'package:xplayer/data/models/channel_model.dart';

/// 频道过滤纯函数（无副作用，便于单测）。
///
/// - [query]：按频道名称 / ID 模糊匹配（不区分大小写）；为空则不按名称过滤。
/// - [group]：按分组匹配（频道任一 source.groupTitle == group）；为 null 或空表示「全部」。
/// 两者同时给定时取「与」(AND)。
List<Channel> filterChannels(
  List<Channel> all, {
  String query = '',
  String? group,
}) {
  final q = query.trim().toLowerCase();
  final g = (group == null || group.isEmpty) ? null : group;
  return all.where((c) {
    final matchesQuery = q.isEmpty ||
        c.name.toLowerCase().contains(q) ||
        c.id.toLowerCase().contains(q);
    final matchesGroup = g == null || c.source.any((s) => s.groupTitle == g);
    return matchesQuery && matchesGroup;
  }).toList();
}

/// 提取去重后的分组列表（非空 groupTitle，保持首次出现顺序）。
List<String> distinctGroups(List<Channel> all) {
  final seen = <String>{};
  final result = <String>[];
  for (final c in all) {
    for (final s in c.source) {
      final g = s.groupTitle.trim();
      if (g.isNotEmpty && seen.add(g)) result.add(g);
    }
  }
  return result;
}
