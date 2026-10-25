import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/xplayer_player.dart';

void main() {
  test(
    'resume restores an interrupted session without leaking an owner',
    () async {
      var activations = 0;
      var deactivations = 0;
      final coordinator = AudioSessionCoordinator(
        activate: () async {
          activations++;
        },
        deactivate: () async {
          deactivations++;
        },
      );
      expect(await coordinator.reactivate(), isFalse);
      final lease = await coordinator.acquire();
      expect(await coordinator.reactivate(), isTrue);
      await lease.release();
      expect(activations, 2);
      expect(deactivations, 1);
      expect(await coordinator.reactivate(), isFalse);
    },
  );
  test('resume waits for the previous release and new acquisition', () async {
    final gate = Completer<void>();
    final events = <String>[];
    final coordinator = AudioSessionCoordinator(
      activate: () async {
        events.add('activate');
      },
      deactivate: () async {
        events.add('deactivate');
        await gate.future;
      },
    );
    final first = await coordinator.acquire();
    final released = first.release();
    final second = coordinator.acquire();
    final resumed = coordinator.reactivate();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['activate', 'deactivate']);
    gate.complete();
    await released;
    final lease = await second;
    expect(await resumed, isTrue);
    expect(events, ['activate', 'deactivate', 'activate', 'activate']);
    await lease.release();
  });
  test('concurrent duplicate releases share one deactivation future', () async {
    final gate = Completer<void>();
    var releases = 0;
    final coordinator = AudioSessionCoordinator(
      activate: () async {},
      deactivate: () async {
        releases++;
        await gate.future;
      },
    );
    final lease = await coordinator.acquire();
    final first = lease.release();
    final second = lease.release();
    expect(identical(first, second), isTrue);
    gate.complete();
    await Future.wait([first, second]);
    expect(releases, 1);
  });

  test('a failed deactivation does not poison the next player', () async {
    var activations = 0;
    var deactivations = 0;
    final coordinator = AudioSessionCoordinator(
      activate: () async {
        activations++;
      },
      deactivate: () async {
        deactivations++;
        if (deactivations == 1) {
          throw StateError('route temporarily unavailable');
        }
      },
    );
    final first = await coordinator.acquire();
    await expectLater(first.release(), throwsStateError);
    final second = await coordinator.acquire();
    await second.release();
    expect(activations, 2);
    expect(deactivations, 2);
  });

  test(
    'concurrent players share one activation until the last release',
    () async {
      final ready = Completer<void>();
      final events = <String>[];
      final coordinator = AudioSessionCoordinator(
        activate: () async {
          events.add('activate');
          await ready.future;
        },
        deactivate: () async {
          events.add('deactivate');
        },
      );
      final first = coordinator.acquire();
      final second = coordinator.acquire();
      await Future<void>.delayed(Duration.zero);
      expect(events, ['activate']);
      ready.complete();
      final a = await first;
      final b = await second;
      await a.release();
      await a.release();
      expect(events, ['activate']);
      await b.release();
      expect(events, ['activate', 'deactivate']);
    },
  );

  test('new activation waits for asynchronous previous deactivation', () async {
    final gate = Completer<void>();
    final events = <String>[];
    final coordinator = AudioSessionCoordinator(
      activate: () async {
        events.add('activate');
      },
      deactivate: () async {
        events.add('deactivate');
        await gate.future;
      },
    );
    final a = await coordinator.acquire();
    final released = a.release();
    final next = coordinator.acquire();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['activate', 'deactivate']);
    gate.complete();
    await released;
    final b = await next;
    expect(events, ['activate', 'deactivate', 'activate']);
    await b.release();
  });

  test(
    'denied activation does not poison the queue or leak a reference',
    () async {
      var denied = true;
      var deactivations = 0;
      final coordinator = AudioSessionCoordinator(
        activate: () async {
          if (denied) throw StateError('denied');
        },
        deactivate: () async {
          deactivations++;
        },
      );
      await expectLater(coordinator.acquire(), throwsStateError);
      denied = false;
      final lease = await coordinator.acquire();
      await lease.release();
      expect(deactivations, 1);
    },
  );
}
