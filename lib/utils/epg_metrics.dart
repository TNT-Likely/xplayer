import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';

/// EPG 时间轴的纯几何 / 数据换算(无 Flutter 依赖,可单测)。
class EpgMetrics {
  final DateTime windowStart;
  final DateTime windowEnd;
  final double pxPerMinute;
  final double rowHeight;
  final double channelColWidth;
  final double timeAxisHeight;
  final double minBlockWidth;

  const EpgMetrics({
    required this.windowStart,
    required this.windowEnd,
    this.pxPerMinute = 4,
    this.rowHeight = 64,
    this.channelColWidth = 96,
    this.timeAxisHeight = 40,
    this.minBlockWidth = 48,
  });

  double get contentWidth =>
      windowEnd.difference(windowStart).inMinutes * pxPerMinute;

  double xForTime(DateTime t) =>
      t.difference(windowStart).inMinutes * pxPerMinute;

  double widthForRange(DateTime start, DateTime stop) {
    final w = stop.difference(start).inMinutes * pxPerMinute;
    return w < minBlockWidth ? minBlockWidth : w;
  }

  /// 窗口 = [min(节目最早, 今天00:00), max(节目最晚, 今天24:00)]
  factory EpgMetrics.fromProgrammes(List<Programme> programmes,
      {DateTime? now}) {
    final n = now ?? DateTime.now();
    final todayStart = DateTime(n.year, n.month, n.day);
    var start = todayStart;
    var end = todayStart.add(const Duration(days: 1));
    for (final p in programmes) {
      if (p.start.isBefore(start)) start = p.start;
      if (p.stop.isAfter(end)) end = p.stop;
    }
    return EpgMetrics(windowStart: start, windowEnd: end);
  }
}

/// 当前播放列表里「有 EPG」的频道(存在 programme.channel == channel.id)。
List<Channel> channelsWithEpg(
    List<Channel> channels, List<Programme> programmes) {
  final ids = programmes.map((p) => p.channel.toLowerCase()).toSet();
  return channels.where((c) => ids.contains(c.id.toLowerCase())).toList();
}

/// 某频道的节目,按 start 升序。
List<Programme> programmesFor(List<Programme> all, String channelId) {
  final id = channelId.toLowerCase();
  final list = all.where((p) => p.channel.toLowerCase() == id).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return list;
}

/// 是否正在播:start <= now < stop。
bool isLive(Programme p, DateTime now) =>
    !p.start.isAfter(now) && p.stop.isAfter(now);

/// 某频道从 [now] 起「正在 + 后续」节目(丢弃已结束的),按 start 升序,最多 count 条。
List<Programme> upcomingProgrammes(List<Programme> all, String channelId,
    DateTime now,
    {int count = 8}) {
  final list = programmesFor(all, channelId)
      .where((p) => p.stop.isAfter(now))
      .toList();
  return list.length > count ? list.sublist(0, count) : list;
}
