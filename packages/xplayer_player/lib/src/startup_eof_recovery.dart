/// Allows one reload when a native output transition ends a long HLS item
/// before its clock has actually run. A seek or normal playback disarms it.
class StartupEofRecovery {
  bool _used = false;
  bool _disarmed = false;
  Duration _previous = Duration.zero;
  Duration _progress = Duration.zero;

  void observePosition(Duration position) {
    final delta = position - _previous;
    _previous = position;
    // EOF/seek jumps do not count as playback.
    if (delta > Duration.zero && delta <= const Duration(milliseconds: 500)) {
      _progress += delta;
    }
    if (_progress >= const Duration(milliseconds: 500)) _disarmed = true;
  }

  void userSeek() => _disarmed = true;

  bool takeRecovery(Duration duration) {
    if (_used || _disarmed || duration < const Duration(seconds: 2)) {
      return false;
    }
    _used = true;
    return true;
  }
}
