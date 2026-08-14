/// 相对时间计算。
///
/// 播放列表页需要回答「这个源多久没更新了」——绝对时间戳要求用户自己做减法，
/// 「3 天前」才是可以直接据以判断的信息。
///
/// **本模块不产出任何面向用户的字符串**：它只算出「几个什么单位」，
/// 措辞交给 l10n。纯工具自己拼中文会绕过国际化，也没法测试多语言。
library;

/// 相对时间的粒度。
enum TimeUnit { justNow, minutes, hours, days, months, years }

/// 相对时间的结构化结果：[unit] 决定用哪条文案，[value] 填进占位符。
///
/// [TimeUnit.justNow] 时 [value] 恒为 0，调用方忽略即可。
class RelativeTime {
  final TimeUnit unit;
  final int value;

  const RelativeTime(this.unit, this.value);

  @override
  bool operator ==(Object other) =>
      other is RelativeTime && other.unit == unit && other.value == value;

  @override
  int get hashCode => Object.hash(unit, value);

  @override
  String toString() => 'RelativeTime($unit, $value)';
}

/// 计算 [time] 距 [now] 有多久。[time] 为 null 时返回 null，调用方据此省略整段。
RelativeTime? relativeTime(DateTime? time, DateTime now) {
  if (time == null) return null;
  final d = now.difference(time);

  // 时钟回拨或时间戳来自未来时，不产出「-3 天前」这种东西。
  if (d.isNegative) return const RelativeTime(TimeUnit.justNow, 0);

  if (d.inMinutes < 1) return const RelativeTime(TimeUnit.justNow, 0);
  if (d.inMinutes < 60) return RelativeTime(TimeUnit.minutes, d.inMinutes);
  if (d.inHours < 24) return RelativeTime(TimeUnit.hours, d.inHours);
  if (d.inDays < 30) return RelativeTime(TimeUnit.days, d.inDays);
  if (d.inDays < 365) return RelativeTime(TimeUnit.months, d.inDays ~/ 30);
  return RelativeTime(TimeUnit.years, d.inDays ~/ 365);
}

/// 距上次更新是否久到需要提醒用户。
///
/// 阈值取 7 天：直播源失效通常不会有任何通知，一周没更新就值得提一句。
bool isStale(DateTime? time, DateTime now, {int days = 7}) {
  if (time == null) return false;
  final d = now.difference(time);
  return !d.isNegative && d.inDays >= days;
}
