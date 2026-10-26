import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/src/audio_packet_recovery.dart';
import 'package:xplayer_player/xplayer_player.dart';

void main() {
  AudioPacketRecovery guard() =>
      AudioPacketRecovery(timeout: const Duration(seconds: 3), errorLimit: 8);
  Duration ms(int value) => Duration(milliseconds: value);

  test('only the known packet error enters the recovery path', () {
    expect(AudioPacketRecovery.handles('Error decoding audio.\n'), isTrue);
    for (final message in [
      'HTTP error 403',
      'Could not open codec.',
      'Failed to initialize audio output',
      'Error decoding video.',
      '',
    ]) {
      expect(AudioPacketRecovery.handles(message), isFalse);
    }
  });

  test('requires fresh audio timestamps and an active output to recover', () {
    final recovery = guard();
    recovery.record(ms(0), playing: true);
    expect(
      recovery.sample(
        ms(250),
        playing: true,
        outputReady: true,
        audioPosition: 10,
      ),
      AudioRecoveryDecision.pending,
    );
    expect(
      recovery.sample(
        ms(500),
        playing: true,
        outputReady: true,
        audioPosition: 10.4,
      ),
      AudioRecoveryDecision.recovered,
    );
    expect(recovery.pending, isFalse);
  });

  test('video progress cannot stand in for absent or silent audio output', () {
    final recovery = guard();
    recovery.record(ms(0), playing: true);
    recovery.sample(
      ms(500),
      playing: true,
      outputReady: false,
      audioPosition: 20,
    );
    recovery.sample(
      ms(1000),
      playing: true,
      outputReady: false,
      audioPosition: 21,
    );
    expect(
      recovery.checkDeadline(ms(3000), playing: true),
      AudioRecoveryDecision.failed,
    );
  });

  test('a frozen audio clock fails within the recovery deadline', () {
    final recovery = guard();
    recovery.record(ms(0), playing: true);
    for (var tick = 250; tick < 3000; tick += 250) {
      expect(
        recovery.sample(
          ms(tick),
          playing: true,
          outputReady: true,
          audioPosition: 2,
        ),
        AudioRecoveryDecision.pending,
      );
    }
    expect(
      recovery.checkDeadline(ms(3000), playing: true),
      AudioRecoveryDecision.failed,
    );
  });

  test('repeated errors never extend the first recovery deadline', () {
    final recovery = guard();
    for (var tick = 0; tick < 3000; tick += 500) {
      expect(
        recovery.record(ms(tick), playing: true),
        AudioRecoveryDecision.pending,
      );
    }
    expect(
      recovery.record(ms(3000), playing: true),
      AudioRecoveryDecision.failed,
    );
  });

  test(
    'recovered but excessive packet errors still exhaust a bounded budget',
    () {
      final recovery = guard();
      for (var i = 0; i < 8; i++) {
        final at = i * 500;
        expect(
          recovery.record(ms(at), playing: true),
          AudioRecoveryDecision.pending,
        );
        recovery.sample(
          ms(at + 100),
          playing: true,
          outputReady: true,
          audioPosition: 1,
        );
        expect(
          recovery.sample(
            ms(at + 400),
            playing: true,
            outputReady: true,
            audioPosition: 1.4,
          ),
          AudioRecoveryDecision.recovered,
        );
      }
      expect(
        recovery.record(ms(4000), playing: true),
        AudioRecoveryDecision.failed,
      );
      expect(
        recovery.record(ms(15000), playing: true),
        AudioRecoveryDecision.pending,
      );
    },
  );

  test(
    'user pause suspends recovery without mistaking it for a stalled decoder',
    () {
      final recovery = guard();
      recovery.record(ms(0), playing: false);
      expect(
        recovery.checkDeadline(ms(30000), playing: false),
        AudioRecoveryDecision.pending,
      );
      expect(
        recovery.checkDeadline(ms(31000), playing: true),
        AudioRecoveryDecision.pending,
      );
      expect(
        recovery.checkDeadline(ms(33999), playing: true),
        AudioRecoveryDecision.pending,
      );
      expect(
        recovery.checkDeadline(ms(34000), playing: true),
        AudioRecoveryDecision.failed,
      );
    },
  );

  test('seek and timestamp discontinuities do not falsely prove recovery', () {
    final recovery = guard();
    recovery.record(ms(0), playing: true);
    recovery.sample(
      ms(100),
      playing: true,
      outputReady: true,
      audioPosition: 100,
    );
    expect(
      recovery.sample(
        ms(300),
        playing: true,
        outputReady: true,
        audioPosition: 300,
      ),
      AudioRecoveryDecision.pending,
    );
    expect(
      recovery.sample(
        ms(500),
        playing: true,
        outputReady: true,
        audioPosition: 1,
      ),
      AudioRecoveryDecision.pending,
    );
    expect(
      recovery.sample(
        ms(800),
        playing: true,
        outputReady: true,
        audioPosition: 1.4,
      ),
      AudioRecoveryDecision.recovered,
    );
  });

  test('a new bad packet invalidates earlier recovery evidence', () {
    final recovery = guard();
    recovery.record(ms(0), playing: true);
    recovery.sample(
      ms(100),
      playing: true,
      outputReady: true,
      audioPosition: 1,
    );
    recovery.record(ms(200), playing: true);
    expect(
      recovery.sample(
        ms(500),
        playing: true,
        outputReady: true,
        audioPosition: 1.5,
      ),
      AudioRecoveryDecision.pending,
    );
    expect(
      recovery.sample(
        ms(800),
        playing: true,
        outputReady: true,
        audioPosition: 1.8,
      ),
      AudioRecoveryDecision.recovered,
    );
  });

  test('nonfinite timestamps and cancellation cannot complete recovery', () {
    final recovery = guard();
    recovery.record(ms(0), playing: true);
    expect(
      recovery.sample(
        ms(200),
        playing: true,
        outputReady: true,
        audioPosition: double.nan,
      ),
      AudioRecoveryDecision.pending,
    );
    recovery.cancel();
    expect(
      recovery.checkDeadline(ms(9000), playing: true),
      AudioRecoveryDecision.none,
    );
  });

  test(
    'invalid recovery configuration fails before allocating the native player',
    () {
      expect(
        const PlaybackConfiguration(
          audioPacketRecoveryTimeout: Duration.zero,
        ).validate,
        throwsArgumentError,
      );
      expect(
        const PlaybackConfiguration(audioPacketErrorLimit: 0).validate,
        throwsArgumentError,
      );
    },
  );

  test('concurrent disposal callers wait on the same completion', () async {
    final backend = MediaKitBackend();
    final first = backend.dispose();
    expect(identical(first, backend.dispose()), isTrue);
    await first;
    expect(identical(first, backend.dispose()), isTrue);
  });
}
