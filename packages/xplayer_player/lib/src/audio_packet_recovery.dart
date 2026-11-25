import 'dart:collection';

enum AudioRecoveryDecision {
  none,
  pending,
  recovered,
  timedOut,
  errorLimitExceeded,
}

/// A packet error is recoverable only after audio output actually advances.
/// Uses monotonic elapsed time supplied by the backend, not wall-clock time.
class AudioPacketRecovery {
  AudioPacketRecovery({
    required this.timeout,
    required this.errorLimit,
    required this.bufferingAllowance,
  });

  final Duration timeout;
  final int errorLimit;
  final Duration bufferingAllowance;
  final _errors = Queue<Duration>();
  bool pending = false;
  Duration? _startedAt;
  Duration? _activeSince;
  Duration _activeElapsed = Duration.zero;
  double? _lastAudioPosition;
  double _progress = 0;

  // mpv ad_lavc emits this for rejected packets as well as fatal failures.
  // Missing codecs, devices, HTTP failures and unknown errors stay fatal.
  static bool handles(String message) =>
      message.trim() == 'Error decoding audio.';

  AudioRecoveryDecision record(
    Duration now, {
    required bool playing,
    bool buffering = false,
  }) {
    while (_errors.isNotEmpty &&
        now - _errors.first > const Duration(seconds: 10)) {
      _errors.removeFirst();
    }
    _errors.add(now);
    if (_errors.length > errorLimit) {
      cancel();
      return AudioRecoveryDecision.errorLimitExceeded;
    }
    pending = true;
    _resetSamples();
    return checkDeadline(now, playing: playing, buffering: buffering);
  }

  void pause() {
    _startedAt = null;
    _activeSince = null;
    _activeElapsed = Duration.zero;
    _resetSamples();
  }

  void _resetSamples() {
    _lastAudioPosition = null;
    _progress = 0;
  }

  AudioRecoveryDecision checkDeadline(
    Duration now, {
    required bool playing,
    bool buffering = false,
  }) {
    if (!pending) return AudioRecoveryDecision.none;
    if (!playing) {
      pause();
      return AudioRecoveryDecision.pending;
    }
    final startedAt = _startedAt ??= now;
    if (buffering) {
      if (_activeSince case final activeSince?) {
        _activeElapsed += now - activeSince;
        _activeSince = null;
        _resetSamples();
      }
    } else {
      _activeSince ??= now;
    }
    final currentActive = now - (_activeSince ?? now);
    // Slow delivery is separate from a stalled decoder. Give the decoder
    // its active budget while also bounding the entire unpaused episode.
    if (_activeElapsed + currentActive >= timeout ||
        now - startedAt >= timeout + bufferingAllowance) {
      cancel();
      return AudioRecoveryDecision.timedOut;
    }
    return AudioRecoveryDecision.pending;
  }

  AudioRecoveryDecision sample(
    Duration now, {
    required bool playing,
    bool buffering = false,
    required bool outputReady,
    double? audioPosition,
  }) {
    final decision = checkDeadline(now, playing: playing, buffering: buffering);
    if (decision != AudioRecoveryDecision.pending || !playing || buffering) {
      return decision;
    }
    if (!outputReady || audioPosition == null || !audioPosition.isFinite) {
      _resetSamples();
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
