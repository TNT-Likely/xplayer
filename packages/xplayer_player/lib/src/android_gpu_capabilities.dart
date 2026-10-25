import 'dart:async';

import 'package:flutter/services.dart';

/// A bounded driver probe. Missing/older host adapters retain normal rendering.
Future<Map<String, Object?>> queryAndroidGpuCapabilities({
  Duration timeout = const Duration(seconds: 1),
}) async {
  try {
    return await const MethodChannel(
              'com.tntlikely.xplayer/decoder_capabilities',
            )
            .invokeMapMethod<String, Object?>('queryEglCapabilities')
            .timeout(timeout) ??
        const {};
  } on MissingPluginException {
    return const {};
  } on PlatformException {
    return const {};
  } on TimeoutException {
    return const {};
  }
}
