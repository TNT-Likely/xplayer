import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/services/player/stall_detector.dart';

void main() {
  // 固定基准时间,t(s) = 基准 + s 秒
  final base = DateTime(2026, 1, 1);
  DateTime t(int s) => base.add(Duration(seconds: s));

  group('StallDetector', () {
    test('位置持续推进 → 永不判定卡死', () {
      final d = StallDetector(threshold: const Duration(seconds: 8));
      for (var s = 0; s <= 20; s += 2) {
        final stalled = d.sample(
          eligible: true,
          position: Duration(seconds: s), // 每次采样位置都在走
          now: t(s),
        );
        expect(stalled, isFalse);
      }
    });

    test('位置冻结:满阈值(8s)才判定卡死,期间不误报', () {
      final d = StallDetector(threshold: const Duration(seconds: 8));
      expect(d.sample(eligible: true, position: const Duration(seconds: 5), now: t(0)), isFalse); // 基线
      expect(d.sample(eligible: true, position: const Duration(seconds: 5), now: t(2)), isFalse);
      expect(d.sample(eligible: true, position: const Duration(seconds: 5), now: t(4)), isFalse);
      expect(d.sample(eligible: true, position: const Duration(seconds: 5), now: t(6)), isFalse);
      // 满 8 秒 → 卡死
      expect(d.sample(eligible: true, position: const Duration(seconds: 5), now: t(8)), isTrue);
    });

    test('缓冲/暂停(eligible=false)期间重置计时,不把正常停滞算作卡死', () {
      final d = StallDetector(threshold: const Duration(seconds: 8));
      expect(d.sample(eligible: true, position: const Duration(seconds: 5), now: t(0)), isFalse);
      // 4 秒后进入缓冲(不 eligible)→ 重置计时
      expect(d.sample(eligible: false, position: const Duration(seconds: 5), now: t(4)), isFalse);
      // 恢复在播但位置仍未动:从 t4 重新计,t11 仅 7 秒 → 不触发
      expect(d.sample(eligible: true, position: const Duration(seconds: 5), now: t(11)), isFalse);
      // t12 距 t4 满 8 秒 → 触发
      expect(d.sample(eligible: true, position: const Duration(seconds: 5), now: t(12)), isTrue);
    });

    test('触发一次后计时重置,不会每次采样连环触发', () {
      final d = StallDetector(threshold: const Duration(seconds: 8));
      d.sample(eligible: true, position: Duration.zero, now: t(0));
      expect(d.sample(eligible: true, position: Duration.zero, now: t(8)), isTrue);
      // 紧接着的采样不应再触发(调用方正在重连)
      expect(d.sample(eligible: true, position: Duration.zero, now: t(10)), isFalse);
      // 若一直没人处理,再满一个阈值周期才会再次触发
      expect(d.sample(eligible: true, position: Duration.zero, now: t(16)), isTrue);
    });

    test('位置恢复推进 → 计时清零,之后再冻结要重新满阈值', () {
      final d = StallDetector(threshold: const Duration(seconds: 8));
      d.sample(eligible: true, position: const Duration(seconds: 1), now: t(0));
      d.sample(eligible: true, position: const Duration(seconds: 1), now: t(6)); // 冻 6 秒
      d.sample(eligible: true, position: const Duration(seconds: 2), now: t(7)); // 又动了 → 清零
      expect(d.sample(eligible: true, position: const Duration(seconds: 2), now: t(14)), isFalse); // 距 t7 才 7 秒
      expect(d.sample(eligible: true, position: const Duration(seconds: 2), now: t(15)), isTrue); // 满 8 秒
    });

    test('reset() 后从头建立基线(切台/重连后不残留旧计时)', () {
      final d = StallDetector(threshold: const Duration(seconds: 8));
      d.sample(eligible: true, position: Duration.zero, now: t(0));
      d.sample(eligible: true, position: Duration.zero, now: t(6));
      d.reset();
      // reset 后第一次采样只建基线,即使时间已过很久也不触发
      expect(d.sample(eligible: true, position: Duration.zero, now: t(20)), isFalse);
      expect(d.sample(eligible: true, position: Duration.zero, now: t(27)), isFalse);
      expect(d.sample(eligible: true, position: Duration.zero, now: t(28)), isTrue);
    });
  });
}
