import 'package:xplayer/data/models/programme_model.dart';

/// EPG 节目索引:构建一次 Map,供首页大直播卡 / 频道卡等高频查询使用。
///
/// 背景:`epg_metrics.dart` 里的 [programmesFor] 是 O(节目总数) 线性过滤,
/// 首页网格每张卡都要查「当前节目」,O(频道×节目) 在几千频道下不可接受;
/// 这里按频道键(小写)建桶 + 起始时间有序,查询单次 O(log n)。
///
/// 频道键与 `epg_screen` / [programmesFor] 一致:`programme.channel` 与
/// `channel.id` 均转小写后匹配。
class EpgIndex {
  /// 频道键(小写) → 该频道节目,按 start 升序。
  final Map<String, List<Programme>> _byChannel;

  EpgIndex._(this._byChannel);

  factory EpgIndex.fromProgrammes(List<Programme> programmes) {
    final map = <String, List<Programme>>{};
    for (final p in programmes) {
      (map[p.channel.toLowerCase()] ??= []).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    return EpgIndex._(map);
  }

  static final EpgIndex empty = EpgIndex._(const {});

  /// 该频道 [now] 时刻正在播出的节目;无 EPG 或不在任何时段内返回 null。
  /// 二分找最后一个 start <= now 的节目,其 stop > now 即正在播。
  Programme? currentFor(String channelId, DateTime now) {
    final list = _byChannel[channelId.toLowerCase()];
    if (list == null || list.isEmpty) return null;
    var lo = 0, hi = list.length - 1, idx = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (!list[mid].start.isAfter(now)) {
        idx = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (idx < 0) return null;
    final p = list[idx];
    return p.stop.isAfter(now) ? p : null;
  }

  /// 该频道 [now] 之后的下一档节目(第一个 start > now);无则返回 null。
  Programme? nextFor(String channelId, DateTime now) {
    final list = _byChannel[channelId.toLowerCase()];
    if (list == null || list.isEmpty) return null;
    var lo = 0, hi = list.length - 1, idx = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (list[mid].start.isAfter(now)) {
        idx = mid;
        hi = mid - 1;
      } else {
        lo = mid + 1;
      }
    }
    return idx >= 0 ? list[idx] : null;
  }

  /// 播放进度 0.0 ~ 1.0;[p] 非当前节目或区间非法时返回 null。
  static double? progressOf(Programme? p, DateTime now) {
    if (p == null) return null;
    final total = p.stop.difference(p.start).inMilliseconds;
    if (total <= 0) return null;
    final elapsed = now.difference(p.start).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
