import 'dart:async';

/// Serializes acquisition/release of the process-wide Apple audio session.
/// Multiple players must not deactivate a session still used by another one.
class AudioSessionCoordinator {
  AudioSessionCoordinator({required this.activate, required this.deactivate});
  final Future<void> Function() activate;
  final Future<void> Function() deactivate;
  int _users = 0;
  Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<AudioSessionLease> acquire() => _serialize(() async {
    if (_users == 0) await activate();
    _users++;
    return AudioSessionLease._(
      () => _serialize(() async {
        _users--;
        if (_users == 0) await deactivate();
      }),
    );
  });
}

class AudioSessionLease {
  AudioSessionLease._(this._release);
  final Future<void> Function() _release;
  Future<void>? _releaseFuture;

  Future<void> release() => _releaseFuture ??= _release();
}
