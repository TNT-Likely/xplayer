import 'dart:async';

import 'package:flutter/services.dart';

/// Coalesces concurrent requests, including failures and timed-out probes.
/// Driver capabilities are stable for the lifetime of the application process.
class AndroidGpuCapabilityProbe {
  Future<Map<String, Object?>>? _result;

  /// The first call determines the budget. Later calls reuse the same result.
  Future<Map<String, Object?>> query({
    Duration timeout = const Duration(seconds: 1),
  }) {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive');
    }
    return _result ??= _query(timeout);
  }
}

final _processProbe = AndroidGpuCapabilityProbe();

/// A bounded, shared driver probe. Missing adapters retain normal rendering.
Future<Map<String, Object?>> queryAndroidGpuCapabilities({
  Duration timeout = const Duration(seconds: 1),
}) => _processProbe.query(timeout: timeout);

Future<Map<String, Object?>> _query(Duration timeout) async {
  try {
    final result = await const MethodChannel(
      'com.tntlikely.xplayer/decoder_capabilities',
    ).invokeMapMethod<String, Object?>('queryEglCapabilities').timeout(timeout);
    return Map.unmodifiable(result ?? const {});
  } on MissingPluginException {
    return const {};
  } on PlatformException {
    return const {};
  } on TimeoutException {
    return const {};
  }
}
