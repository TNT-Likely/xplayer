import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/src/startup_eof_recovery.dart';

void main() {
  test('EOF jump during initial output transition permits only one reload', () {
    final recovery = StartupEofRecovery();
    recovery.observePosition(const Duration(seconds: 4));
    expect(recovery.takeRecovery(const Duration(seconds: 4)), isTrue);
    expect(recovery.takeRecovery(const Duration(seconds: 4)), isFalse);
  });

  test('normal clock progress disarms startup recovery', () {
    final recovery = StartupEofRecovery();
    for (var ms = 100; ms <= 600; ms += 100) {
      recovery.observePosition(Duration(milliseconds: ms));
    }
    expect(recovery.takeRecovery(const Duration(seconds: 4)), isFalse);
  });

  test('user seeking and short items do not restart playback', () {
    final recovery = StartupEofRecovery();
    expect(recovery.takeRecovery(const Duration(milliseconds: 900)), isFalse);
    recovery.userSeek();
    expect(recovery.takeRecovery(const Duration(seconds: 4)), isFalse);
  });
}
