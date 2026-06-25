import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/services/sleep_timer.dart';

void main() {
  test('initially inactive', () {
    final t = SleepTimer();
    expect(t.isActive, false);
    expect(t.deadline.value, isNull);
    t.dispose();
  });

  test('start sets a future deadline; cancel clears it', () {
    final t = SleepTimer();
    t.start(const Duration(minutes: 30), onFire: () {});
    expect(t.isActive, true);
    expect(t.deadline.value, isNotNull);
    t.cancel();
    expect(t.isActive, false);
    expect(t.deadline.value, isNull);
    t.dispose();
  });

  test('remaining is positive after start', () {
    final t = SleepTimer();
    t.start(const Duration(minutes: 10), onFire: () {});
    final r = t.remaining;
    expect(r, isNotNull);
    expect(r!.inSeconds, greaterThan(0));
    expect(r.inMinutes, lessThanOrEqualTo(10));
    t.cancel();
    t.dispose();
  });
}
