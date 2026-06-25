import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import '_fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('初始 none', () {
    final c = MiniPlayerController();
    expect(c.mode, PlayerMode.none);
    expect(c.backend, isNull);
  });
  test('enterMini 持有 backend 且 mode=mini', () {
    final c = MiniPlayerController();
    final b = FakeBackend();
    c.enterMini(b, ch('c1'), const []);
    expect(c.mode, PlayerMode.mini);
    expect(c.backend, same(b));
    expect(c.hasMini, true);
  });
  test('take 取回 backend 并回 fullscreen(不销毁)', () {
    final c = MiniPlayerController();
    final b = FakeBackend();
    c.enterMini(b, ch('c1'), const []);
    final taken = c.take();
    expect(taken, same(b));
    expect(c.mode, PlayerMode.fullscreen);
    expect(b.disposed, false);
  });
  test('close 销毁并清空', () async {
    final c = MiniPlayerController();
    final b = FakeBackend();
    c.enterMini(b, ch('c1'), const []);
    await c.close();
    expect(c.mode, PlayerMode.none);
    expect(c.backend, isNull);
    expect(b.disposed, true);
  });
}
