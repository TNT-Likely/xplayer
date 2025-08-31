import 'dart:collection';

class AppLogger {
  static bool debugEnabled = false; // 默认关闭
  static final List<String> _logs = <String>[];

  static void log(String message) {
    if (!debugEnabled) return;
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    _logs.add('[$ts] $message');
    if (_logs.length > 2000) {
      _logs.removeRange(0, _logs.length - 2000);
    }
  }

  static UnmodifiableListView<String> get logs => UnmodifiableListView(_logs);

  static void clear() => _logs.clear();
}
