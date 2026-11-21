import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:xplayer/services/player/video_player_backend.dart';

void main() {
  testWidgets('Windows video view detaches while native release is pending', (
    tester,
  ) async {
    const channel = MethodChannel('video_player_win');
    final messenger = tester.binding.defaultBinaryMessenger;
    final calls = <String>[];
    final shutdownStarted = Completer<void>.sync();
    final finishShutdown = Completer<void>.sync();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'openVideo') {
        return {
          'result': true,
          'textureId': 42,
          'videoWidth': 640,
          'videoHeight': 360,
          'volume': 1.0,
          'duration': 10000,
        };
      }
      if (call.method == 'shutdown') {
        shutdownStarted.complete();
        await finishShutdown.future;
      }
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    WindowsVideoPlayer.registerWith();

    final backend = VideoPlayerBackend();
    await tester.runAsync(
      () => backend.initialize('https://example.com/live.m3u8'),
    );
    await tester.pumpWidget(Center(child: backend.buildView()));
    expect(tester.widget<Texture>(find.byType(Texture)).textureId, 42);

    late Future<void> release;
    try {
      await tester.runAsync(() async {
        release = backend.dispose();
        await Future.any([shutdownStarted.future, release]);
      });
      await tester.pump();
      expect(calls, contains('shutdown'));
      expect(calls, isNot(contains('dispose')));
      final retainedOldTexture = find.byType(Texture).evaluate().isNotEmpty;

      await tester.pumpWidget(Center(child: backend.buildView()));
      expect(tester.takeException(), isNull);
      expect(find.byType(Texture), findsNothing);
      expect(retainedOldTexture, isFalse);
      expect(backend.notifier.value.isInitialized, isFalse);
      expect(backend.dispose(), same(release));
    } finally {
      await tester.runAsync(() async {
        finishShutdown.complete();
        await release;
      });
    }
    expect(calls.where((call) => call == 'dispose'), hasLength(1));
  });
}
