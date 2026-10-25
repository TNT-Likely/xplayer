import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/src/android_gpu_capabilities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.tntlikely.xplayer/decoder_capabilities');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('retains exact EGL probe evidence for the affected driver', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'queryEglCapabilities');
      return {
        'needsDebugContext': true,
        'zeroFlagsError': 0x3004,
        'plainContextSupported': true,
        'debugContextSupported': true,
      };
    });
    final result = await queryAndroidGpuCapabilities();
    expect(result['needsDebugContext'], isTrue);
    expect(result['zeroFlagsError'], 0x3004);
  });

  test('normal driver keeps its normal context', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      return {'needsDebugContext': false, 'zeroFlagsError': 0x3000};
    });
    expect((await queryAndroidGpuCapabilities())['needsDebugContext'], isFalse);
  });

  test('older hosts without the channel can still open media', () async {
    expect(await queryAndroidGpuCapabilities(), isEmpty);
  });

  test('native probe errors do not block playback', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'EGL_UNAVAILABLE');
    });
    expect(await queryAndroidGpuCapabilities(), isEmpty);
  });

  test('a stuck driver probe has a bounded startup cost', () async {
    final pending = Completer<Map<String, Object?>>();
    messenger.setMockMethodCallHandler(channel, (_) => pending.future);
    expect(
      await queryAndroidGpuCapabilities(
        timeout: const Duration(milliseconds: 5),
      ),
      isEmpty,
    );
    pending.complete({'needsDebugContext': true});
  });
}
