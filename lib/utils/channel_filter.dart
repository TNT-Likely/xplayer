import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/utils/channel_normalize.dart';

/// 频道过滤纯函数（无副作用，便于单测）。
///
/// - [query]：按频道名称 / ID 模糊匹配（不区分大小写）；为空则不按名称过滤。
///   仍然匹配 ID，因为规范化之后 name 里不再含 `@HD`、地区码这类原始串，
///   用户若按老习惯搜 `CCTV1.CN` 也应当搜得到。
/// - [group]：按分组标签匹配。分组是**多标签**的——`group-title` 里的
///   `Entertainment;Family;General` 会被拆成三个独立标签，频道同属其中任意一个即命中。
///   为 null 或空表示「全部」。
/// - [uncategorized]：传入时表示筛选「未分类」，即不带任何分组标签的频道。
///
/// 多个条件同时给定时取「与」(AND)。
List<Channel> filterChannels(
  List<Channel> all, {
  String query = '',
  String? group,
  bool uncategorized = false,
}) {
  final q = query.trim().toLowerCase();
  final g = (group == null || group.isEmpty) ? null : group.toLowerCase();
  return all.where((c) {
    final matchesQuery = q.isEmpty ||
        c.name.toLowerCase().contains(q) ||
        c.id.toLowerCase().contains(q);
    if (!matchesQuery) return false;

    if (uncategorized) return c.groups.isEmpty;
    if (g == null) return true;
    return c.groups.any((t) => t.toLowerCase() == g);
  }).toList();
}

/// 提取去重后的分组标签列表（保持首次出现顺序）。
///
/// 与旧实现的区别：`group-title` 会先按 `;` 拆成多标签。旧实现把
/// `Entertainment;Family;General` 当成一个组名，导致分组列表里出现大量
/// 只含一个频道的怪组、弹窗里还溢出到看不全。拆开后组数收敛到十几个真实分类。
///
/// `Undefined` 不在返回列表里——它不是分组，是解析失败的残留。
/// 需要「未分类」入口时由 UI 层自行追加，并配合 [filterChannels] 的
/// `uncategorized` 参数使用。
List<String> distinctGroups(List<Channel> all) {
  final seen = <String>{};
  final result = <String>[];
  for (final c in all) {
    for (final s in c.source) {
      for (final g in splitGroupTitle(s.groupTitle)) {
        if (seen.add(g.toLowerCase())) result.add(g);
      }
    }
  }
  return result;
}

/// 每个分组标签下的频道数。用于分组标签上的计数——数字本身就是选择依据。
Map<String, int> groupCounts(List<Channel> all) {
  final counts = <String, int>{};
  for (final c in all) {
    for (final g in c.groups) {
      counts[g] = (counts[g] ?? 0) + 1;
    }
  }
  return counts;
}

/// 不带任何分组标签的频道数（界面上的「未分类」）。
int uncategorizedCount(List<Channel> all) =>
    all.where((c) => c.groups.isEmpty).length;
