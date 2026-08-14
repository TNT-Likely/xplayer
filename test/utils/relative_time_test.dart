import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/utils/relative_time.dart';

void main() {
  final now = DateTime(2026, 8, 14, 12, 0);

  group('relativeTime', () {
    test('null 返回 null,调用方据此省略整段', () {
      expect(relativeTime(null, now), isNull);
    });

    test('一分钟内算「刚刚」,value 恒为 0', () {
      expect(relativeTime(now.subtract(const Duration(seconds: 5)), now),
          const RelativeTime(TimeUnit.justNow, 0));
      expect(relativeTime(now, now), const RelativeTime(TimeUnit.justNow, 0));
    });

    test('分钟 / 小时 / 天 / 月 / 年 逐级切换', () {
      expect(relativeTime(now.subtract(const Duration(minutes: 3)), now),
          const RelativeTime(TimeUnit.minutes, 3));
      expect(relativeTime(now.subtract(const Duration(hours: 5)), now),
          const RelativeTime(TimeUnit.hours, 5));
      expect(relativeTime(now.subtract(const Duration(days: 3)), now),
          const RelativeTime(TimeUnit.days, 3));
      expect(relativeTime(now.subtract(const Duration(days: 60)), now),
          const RelativeTime(TimeUnit.months, 2));
      expect(relativeTime(now.subtract(const Duration(days: 400)), now),
          const RelativeTime(TimeUnit.years, 1));
    });

    test('边界:59 分钟仍是分钟,60 分钟进位到小时', () {
      expect(relativeTime(now.subtract(const Duration(minutes: 59)), now),
          const RelativeTime(TimeUnit.minutes, 59));
      expect(relativeTime(now.subtract(const Duration(minutes: 60)), now),
          const RelativeTime(TimeUnit.hours, 1));
    });

    test('时钟回拨或未来时间戳退回「刚刚」,不产出负数', () {
      final r = relativeTime(now.add(const Duration(days: 3)), now)!;
      expect(r.unit, TimeUnit.justNow);
      expect(r.value, isNonNegative);
    });

    test('不产出任何面向用户的字符串 —— 措辞交给 l10n', () {
      // 这条是护栏:一旦有人在工具里拼中文,国际化就被绕过去了。
      final r = relativeTime(now.subtract(const Duration(days: 3)), now)!;
      expect(r.unit, isA<TimeUnit>());
      expect(r.value, isA<int>());
    });
  });

  group('isStale', () {
    test('默认 7 天阈值 —— 源失效不会有任何通知,一周没更新就值得提一句', () {
      expect(isStale(now.subtract(const Duration(days: 6)), now), isFalse);
      expect(isStale(now.subtract(const Duration(days: 7)), now), isTrue);
      expect(isStale(now.subtract(const Duration(days: 30)), now), isTrue);
    });

    test('阈值可调', () {
      expect(isStale(now.subtract(const Duration(days: 3)), now, days: 2), isTrue);
    });

    test('null 与未来时间都不算陈旧', () {
      expect(isStale(null, now), isFalse);
      expect(isStale(now.add(const Duration(days: 10)), now), isFalse);
    });
  });
}
