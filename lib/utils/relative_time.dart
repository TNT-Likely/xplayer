/// 相对时间描述。
///
/// 播放列表页需要回答「这个源多久没更新了」——绝对时间戳要求用户自己做减法，
/// 「3 天前」才是可以直接据以判断的信息。
///
/// [now] 可注入，便于测试（生产调用处传 `DateTime.now()`）。
String relativeTime(DateTime? time, DateTime now) {
  if (time == null) return '';
  final d = now.difference(time);

  // 时钟回拨或时间戳来自未来时，不显示「-3 天前」这种东西。
  if (d.isNegative) return '刚刚';

  if (d.inMinutes < 1) return '刚刚';
  if (d.inMinutes < 60) return '${d.inMinutes} 分钟前';
  if (d.inHours < 24) return '${d.inHours} 小时前';
  if (d.inDays < 30) return '${d.inDays} 天前';
  if (d.inDays < 365) return '${d.inDays ~/ 30} 个月前';
  return '${d.inDays ~/ 365} 年前';
}

/// 距上次更新是否久到需要提醒用户。
///
/// 阈值取 7 天：直播源失效通常不会有任何通知，一周没更新就值得提一句。
bool isStale(DateTime? time, DateTime now, {int days = 7}) {
  if (time == null) return false;
  final d = now.difference(time);
  return !d.isNegative && d.inDays >= days;
}
