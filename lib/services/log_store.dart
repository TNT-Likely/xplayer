import 'dart:async';

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

extension LogLevelX on LogLevel {
  String get tagText {
    switch (this) {
      case LogLevel.debug:
        return 'D';
      case LogLevel.info:
        return 'I';
      case LogLevel.warning:
        return 'W';
      case LogLevel.error:
        return 'E';
    }
  }
}

class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;
  LogEntry(this.level, this.tag, this.message) : time = DateTime.now();

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _three(int n) => n.toString().padLeft(3, '0');

  String get timeText =>
      '${_two(time.hour)}:${_two(time.minute)}:${_two(time.second)}.${_three(time.millisecond)}';

  String format() => '$timeText ${level.tagText}/$tag: $message';
}

/// 全应用统一日志中心:进程内环形缓冲 + 监听通知。
/// 应用自身的 Logger、未捕获异常、以及各种诊断结果(播放地址/探流/解码器能力)都写到这里,
/// 跨平台(iPhone 也能看),并可经 HTTP 导出。
class LogStore extends ChangeNotifier {
  LogStore._();
  static final LogStore instance = LogStore._();

  static const int _max = 2000;
  final List<LogEntry> _entries = <LogEntry>[];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  bool _notifyScheduled = false;
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  void add(LogLevel level, String tag, String message) {
    _entries.add(LogEntry(level, tag, message));
    if (_entries.length > _max) {
      _entries.removeRange(0, _entries.length - _max);
    }
    _scheduleNotify();
  }

  void d(String tag, String m) => add(LogLevel.debug, tag, m);
  void i(String tag, String m) => add(LogLevel.info, tag, m);
  void w(String tag, String m) => add(LogLevel.warning, tag, m);
  void e(String tag, String m) => add(LogLevel.error, tag, m);

  void clear() {
    _entries.clear();
    _scheduleNotify();
  }

  /// 导出纯文本(供复制 / HTTP)。可按级别与关键字过滤。
  String exportText({Set<LogLevel>? levels, String filter = ''}) {
    final f = filter.toLowerCase();
    return _entries
        .where((e) =>
            (levels == null || levels.contains(e.level)) &&
            (f.isEmpty ||
                e.message.toLowerCase().contains(f) ||
                e.tag.toLowerCase().contains(f)))
        .map((e) => e.format())
        .join('\n');
  }
}
