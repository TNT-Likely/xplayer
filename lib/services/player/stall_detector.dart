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
    if (_lastPos == null || position > _lastPos!) {
      // 只有位置“向前走”才算真实进展(或首次建立基线)→ 刷新计时。
      // 关键:倒退不算!直播卡死的实测形态是位置随直播窗口前移每 ~6s 向后跳
      // (-3606→-9006→-14306…),若按“变了就算在播”判定,每次倒跳都会重置
      // 计时,看门狗永远凑不满阈值(2.5.12 漏检的实锤根因,见 logcat 取证)。
      _lastPos = position;
      _lastAdvanceAt = now;
      return false;
    }
    _lastPos = position; // 倒退时更新基线但不重置计时:此后真恢复(前进)才算进展
    final since = now.difference(_lastAdvanceAt ?? now);
    if (since >= threshold) {
      _lastAdvanceAt = now; // 触发后重置,给重连留出时间,不每次采样都触发
      return true;
    }
    return false;
  }

  /// 当前已持续停滞多久(自最后一次“向前进展”起)。未建立基线时为零。
  /// 调用方可据此在达到重连阈值前先给用户反馈(如提前亮出缓冲指示)。
  Duration stalledFor(DateTime now) =>
      _lastAdvanceAt == null ? Duration.zero : now.difference(_lastAdvanceAt!);

  /// 切台/重连/重建播放器后调用:清空基线,新会话重新计时。
  void reset() {
    _lastPos = null;
    _lastAdvanceAt = null;
  }
}
