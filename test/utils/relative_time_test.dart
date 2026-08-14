import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/utils/relative_time.dart';

void main() {
  final now = DateTime(2026, 8, 14, 12, 0);

  group('relativeTime', () {
    test('null 返回空串,调用方据此省略整段', () {
      expect(relativeTime(null, now), '');
    });

    test('一分钟内算「刚刚」', () {
      expect(relativeTime(now.subtract(const Duration(seconds: 5)), now), '刚刚');
      expect(relativeTime(now, now), '刚刚');
    });

    test('分钟 / 小时 / 天 / 月 / 年 逐级切换', () {
      expect(relativeTime(now.subtract(const Duration(minutes: 3)), now), '3 分钟前');
      expect(relativeTime(now.subtract(const Duration(hours: 5)), now), '5 小时前');
      expect(relativeTime(now.subtract(const Duration(days: 3)), now), '3 天前');
      expect(relativeTime(now.subtract(const Duration(days: 60)), now), '2 个月前');
      expect(relativeTime(now.subtract(const Duration(days: 400)), now), '1 年前');
    });

    test('边界:59 分钟仍是分钟,60 分钟进位到小时', () {
      expect(relativeTime(now.subtract(const Duration(minutes: 59)), now), '59 分钟前');
      expect(relativeTime(now.subtract(const Duration(minutes: 60)), now), '1 小时前');
    });

    test('时钟回拨或未来时间戳不显示「-3 天前」', () {
      expect(relativeTime(now.add(const Duration(days: 3)), now), '刚刚');
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
