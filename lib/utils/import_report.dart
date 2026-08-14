import 'package:xplayer/data/models/channel_model.dart';

/// 播放列表导入体检报告。
///
/// 设计意图:把脏数据从频道网格里请出去,集中到一个地方交代清楚。
/// 现状是解析异常的条目(缺名、无分组、`Undefined`)混在首页最显眼的位置,
/// 用户既看不懂也没法处理。
///
/// **全部指标都从已缓存的频道现算,不落库。** 这样升级不需要数据库迁移
/// (当前 schema 版本 2,加列要升到 3 并写迁移,风险与收益不匹配)。
///
/// 代价:「因无法解析而被跳过」这类指标算不出来 —— 那些条目从未变成
/// [Channel]。需要它得在导入时埋点并持久化,留作后续。
class ImportReport {
  /// 频道总数（去重后实际可用的条目）。
  final int total;

  /// 名字为空、只能回落到地址显示的频道数。
  final int missingName;

  /// 不带任何分组标签的频道数（界面上的「未分类」）。
  final int uncategorized;

  /// 因 id 相同而被合并的条目数（同一频道来自多个源）。
  final int merged;

  /// 带清晰度标识的频道数。
  final int withQuality;

  /// 带台标的频道数——没有台标的会退回文字牌面。
  final int withLogo;

  /// 已匹配到节目单的频道数。由调用方传入（EPG 数据不在本模块职责内）。
  final int withEpg;

  const ImportReport({
    required this.total,
    required this.missingName,
    required this.uncategorized,
    required this.merged,
    required this.withQuality,
    required this.withLogo,
    required this.withEpg,
  });

  /// 一切正常、没有任何需要用户关注的条目。
  bool get isClean => missingName == 0 && uncategorized == 0;

  /// 需要用户关注的条目总数——用于入口处的角标。
  int get needsAttention => missingName + uncategorized;
}

/// 从频道列表现算一份体检报告。
///
/// [epgMatched] 由调用方从 EPG 匹配结果传入；不传则记为 0。
ImportReport analyzeChannels(List<Channel> channels, {int epgMatched = 0}) {
  var missingName = 0;
  var uncategorized = 0;
  var merged = 0;
  var withQuality = 0;
  var withLogo = 0;

  for (final c in channels) {
    if (c.name.trim().isEmpty) missingName++;
    if (c.groups.isEmpty) uncategorized++;
    // 一个 Channel 携带多个 Source 即表示它由多条同 id 记录合并而来。
    if (c.source.length > 1) merged += c.source.length - 1;
    if (c.quality != null) withQuality++;
    if (c.logo != null && c.logo!.trim().isNotEmpty) withLogo++;
  }

  return ImportReport(
    total: channels.length,
    missingName: missingName,
    uncategorized: uncategorized,
    merged: merged,
    withQuality: withQuality,
    withLogo: withLogo,
    withEpg: epgMatched,
  );
}
