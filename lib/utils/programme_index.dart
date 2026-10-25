import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/utils/epg_metrics.dart';

/// 页面重建时分组一次；卡片不再逐个扫描整份 XMLTV。
class ProgrammeIndex {
  ProgrammeIndex(Iterable<Programme> programmes) {
    for (final p in programmes) {
      if (p.stop.isAfter(p.start)) {
        (byChannel[p.channel.toLowerCase()] ??= []).add(p);
      }
    }
    for (final list in byChannel.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
  }
  final Map<String, List<Programme>> byChannel = {};
  List<Programme> forChannel(String id) =>
      byChannel[id.toLowerCase()] ?? const [];
  Programme? current(String id, DateTime now) {
    for (final programme in forChannel(id)) {
      if (isLive(programme, now)) return programme;
      if (programme.start.isAfter(now)) break;
    }
    return null;
  }
}

/// XMLTV 使用 UTC；日历窗口先转换为设备本地时间再取整，避免缓存窗口偏移时区。
DateTime epgWindowStart(DateTime base) {
  final local = base.toLocal();
  return DateTime(local.year, local.month, local.day, local.hour);
}
