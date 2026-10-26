import 'dart:collection';

enum AudioRecoveryDecision { none, pending, recovered, failed }

/// A packet error is recoverable only after audio output actually advances.
/// Uses monotonic elapsed time supplied by the backend, not wall-clock time.
class AudioPacketRecovery {
  AudioPacketRecovery({required this.timeout, required this.errorLimit});

  final Duration timeout;
  final int errorLimit;
  final _errors = Queue<Duration>();
  bool pending = false;
  Duration? _startedAt;
  double? _lastAudioPosition;
  double _progress = 0;

  // mpv ad_lavc emits this for rejected packets as well as fatal failures.
  // Missing codecs, devices, HTTP failures and unknown errors stay fatal.
  static bool handles(String message) =>
      message.trim() == 'Error decoding audio.';

  AudioRecoveryDecision record(Duration now, {required bool playing}) {
    while (_errors.isNotEmpty &&
        now - _errors.first > const Duration(seconds: 10)) {
      _errors.removeFirst();
    }
    _errors.add(now);
    if (_errors.length > errorLimit ||
        (pending && _startedAt != null && now - _startedAt! >= timeout)) {
      cancel();
      return AudioRecoveryDecision.failed;
    }
    if (!pending) _startedAt = playing ? now : null;
    pending = true;
    _lastAudioPosition = null;
    _progress = 0;
    return AudioRecoveryDecision.pending;
  }

  void pause() {
    _startedAt = null;
    _lastAudioPosition = null;
    _progress = 0;
  }

  AudioRecoveryDecision checkDeadline(Duration now, {required bool playing}) {
    if (!pending) return AudioRecoveryDecision.none;
    if (!playing) {
      pause();
      return AudioRecoveryDecision.pending;
    }
    _startedAt ??= now;
    if (now - _startedAt! >= timeout) {
      cancel();
      return AudioRecoveryDecision.failed;
    }
    return AudioRecoveryDecision.pending;
  }

  AudioRecoveryDecision sample(
    Duration now, {
    required bool playing,
    required bool outputReady,
    double? audioPosition,
  }) {
    final decision = checkDeadline(now, playing: playing);
    if (decision != AudioRecoveryDecision.pending || !playing) return decision;
    if (!outputReady || audioPosition == null || !audioPosition.isFinite) {
      _lastAudioPosition = null;
      _progress = 0;
      return decision;
    }
    final previous = _lastAudioPosition;
    _lastAudioPosition = audioPosition;
    if (previous != null) {
      final delta = audioPosition - previous;
      // Neither a seek nor a live timestamp discontinuity proves recovery.
      if (delta > 0 && delta < 2) {
        _progress += delta;
      } else if (delta != 0) {
        _progress = 0;
      }
    }
    if (_progress >= 0.25) {
      cancel();
      return AudioRecoveryDecision.recovered;
    }
    return decision;
  }

  void cancel() {
    pending = false;
    pause();
  }
}
