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

  /// A phone call or another plugin can deactivate the shared session while a
  /// player still owns its lease. Restore it before resuming, without adding
  /// another owner or racing the last release.
  Future<bool> reactivate() => _serialize(() async {
    if (_users == 0) return false;
    await activate();
    return true;
  });
}

class AudioSessionLease {
  AudioSessionLease._(this._release);
  final Future<void> Function() _release;
  Future<void>? _releaseFuture;

  Future<void> release() => _releaseFuture ??= _release();
}
