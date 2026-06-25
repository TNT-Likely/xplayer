import 'dart:async';
import 'package:flutter/foundation.dart';

/// 睡眠定时器:到点回调(用于暂停播放)。全局单例,跨页存活。
class SleepTimer {
  Timer? _timer;

  /// 到点的绝对时刻;null 表示未启用。UI 监听它显示倒计时。
  final ValueNotifier<DateTime?> deadline = ValueNotifier<DateTime?>(null);

  bool get isActive => _timer != null;

  /// 剩余时长(未启用返回 null)。
  Duration? get remaining {
    final d = deadline.value;
    if (d == null) return null;
    final r = d.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  /// 启动:[duration] 后触发 [onFire](通常暂停播放)。重复调用会重置。
  void start(Duration duration, {required VoidCallback onFire}) {
    cancel();
    deadline.value = DateTime.now().add(duration);
    _timer = Timer(duration, () {
      _timer = null;
      deadline.value = null;
      onFire();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    deadline.value = null;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    deadline.dispose();
  }
}

/// 全局单例(跨页存活)。
final SleepTimer sleepTimer = SleepTimer();
