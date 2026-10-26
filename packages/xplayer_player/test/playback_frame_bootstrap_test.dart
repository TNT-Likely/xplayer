import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/src/playback_frame_bootstrap.dart';

void main() {
  testWidgets('a hidden view can finish deferred video setup without vsync', (
    tester,
  ) async {
    final binding = tester.binding;
    addTearDown(
      () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    var frames = 0;
    binding.addPostFrameCallback((_) => frames++);
    await tester.runAsync(() async {
      final timer = requestPlaybackFrame(() => true);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      timer.cancel();
    });
    expect(frames, 1);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('completed setup does not request another warm-up frame', (
    tester,
  ) async {
    final binding = tester.binding;
    addTearDown(
      () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    var frames = 0;
    binding.addPostFrameCallback((_) => frames++);
    await tester.runAsync(() async {
      final timer = requestPlaybackFrame(() => false);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      timer.cancel();
    });
    expect(frames, 0);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });
}
