import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/services/player/native_player_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel('native_player');
  const events = MethodChannel('native_player/events');
  final calls = <MethodCall>[];

  Future<void> emit(Map<String, Object> event) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage(
      events.name,
      const StandardMethodCodec().encodeSuccessEnvelope(event),
      (_) => done.complete(),
    );
    await done.future;
  }

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(events, (_) async => null);
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockMethodCallHandler(events, null);
  });

  test(
    'load acknowledgement is not readiness; headers and format reach ExoPlayer',
    () async {
      final backend = NativePlayerBackend();
      var completed = false;
      final initialization = backend
          .initialize(
            'http://test/play?id=1#.m3u8',
            headers: {'Referer': 'https://site.test/'},
          )
          .then((_) => completed = true);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      final args = calls.firstWhere((c) => c.method == 'load').arguments as Map;
      expect(args['url'], 'http://test/play?id=1');
      expect(args['mimeType'], 'application/x-mpegURL');
      expect(args['buffer'], {
        'minMs': 8000,
        'maxMs': 30000,
        'playbackMs': 1500,
        'rebufferMs': 5000,
      });
      expect(args['headers'], {
        'Referer': 'https://site.test/',
        'User-Agent': 'Mozilla/5.0',
      });
      await emit({'event': 'initialized', 'width': 1920, 'height': 1080});
      await initialization;
      expect(completed, isTrue);
      expect(backend.notifier.value.isInitialized, isTrue);
      await backend.dispose();
    },
  );

  test(
    'asynchronous prepare error rejects initialize, allowing engine fallback',
    () async {
      final backend = NativePlayerBackend();
      final result = expectLater(
        backend.initialize('http://test/live.m3u8'),
        throwsA(isA<StateError>()),
      );
      await Future<void>.delayed(Duration.zero);
      await emit({
        'event': 'error',
        'code': 'DECODING_FAILED',
        'msg': 'Unsupported codec',
      });
      await result;
      expect(backend.notifier.value.hasError, isTrue);
      await backend.dispose();
      await backend.dispose();
      expect(calls.where((c) => c.method == 'release').length, 1);
    },
  );
  test(
    'prepare errors are not held behind a pending platform load call',
    () async {
      final load = Completer<void>();
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call);
        if (call.method == 'load') await load.future;
        return null;
      });
      final backend = NativePlayerBackend();
      final result = expectLater(
        backend
            .initialize('http://test/live.m3u8')
            .timeout(const Duration(milliseconds: 500)),
        throwsA(isA<StateError>()),
      );
      await Future<void>.delayed(Duration.zero);
      await emit({
        'event': 'error',
        'code': 'DECODING_FAILED',
        'msg': 'Unsupported codec',
      });
      try {
        await result;
      } finally {
        load.complete();
        await backend.dispose();
      }
    },
  );
  test(
    'native HTTP status remains distinguishable from decoder failure',
    () async {
      final backend = NativePlayerBackend();
      final result = expectLater(
        backend.initialize('http://test/live.m3u8'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('HTTP 403'),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await emit({
        'event': 'error',
        'code': 'ERROR_CODE_IO_BAD_HTTP_STATUS',
        'msg': 'Source error',
        'httpStatus': 403,
      });
      await result;
      expect(backend.diagnostics!.value['httpStatus'], 403);
      expect(backend.notifier.value.errorDescription, contains('HTTP 403'));
      await backend.dispose();
    },
  );
}
