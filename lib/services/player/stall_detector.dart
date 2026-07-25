/// 静默卡死判定:播放器状态"在播"(READY + playWhenReady、不缓冲、无错误),
/// 但播放位置长时间纹丝不动 —— 即播放时钟停走(解码器/音频渲染器卡死等),
/// ExoPlayer 不报 BUFFERING 也不报错,是现有错误重试/长缓冲看门狗之外的第三种故障形态。
///
/// 纯逻辑类:采样由调用方驱动(传入当前时间),便于单测注入时钟。
class StallDetector {
  StallDetector({this.threshold = const Duration(seconds: 8)});

  /// 位置连续停滞多久判定为卡死。
  final Duration threshold;

  Duration? _lastPos;
  DateTime? _lastAdvanceAt;

  /// 采样一次。[eligible] = 形式上在播(已初始化 && isPlaying && !isBuffering && !hasError);
  /// 返回 true 表示判定为卡死(调用方应重连)。触发后内部计时自动重置,避免连环触发。
  bool sample({
    required bool eligible,
    required Duration position,
    required DateTime now,
  }) {
    if (!eligible) {
      // 暂停/缓冲/错误/未初始化:这些状态下位置不动是正常的,重置基线不计时
      _lastPos = position;
      _lastAdvanceAt = now;
      return false;
    }
    if (_lastPos == null || position != _lastPos) {
      // 位置在推进(或首次建立基线)→ 刷新计时
      _lastPos = position;
      _lastAdvanceAt = now;
      return false;
    }
    final since = now.difference(_lastAdvanceAt ?? now);
    if (since >= threshold) {
      _lastAdvanceAt = now; // 触发后重置,给重连留出时间,不每次采样都触发
      return true;
    }
    return false;
  }

  /// 切台/重连/重建播放器后调用:清空基线,新会话重新计时。
  void reset() {
    _lastPos = null;
    _lastAdvanceAt = null;
  }
}
