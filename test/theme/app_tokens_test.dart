import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// WCAG 对比度公式:(较亮亮度 + 0.05) / (较暗亮度 + 0.05)
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

/// 表面阶梯,由深到浅。
const _ladder = <(String, Color)>[
  ('surfaceGround', AppTokens.surfaceGround),
  ('surfaceDefault', AppTokens.surfaceDefault),
  ('surfaceRaised', AppTokens.surfaceRaised),
  ('surfacePlate', AppTokens.surfacePlate),
];

void main() {
  group('表面阶梯', () {
    test('亮度严格递增 —— 阶梯塌了层次感就没了', () {
      for (var i = 1; i < _ladder.length; i++) {
        final (prevName, prev) = _ladder[i - 1];
        final (name, cur) = _ladder[i];
        expect(cur.computeLuminance(), greaterThan(prev.computeLuminance()),
            reason: '$name 应比 $prevName 亮');
      }
    });

    test('频道牌衬底是最亮的一档 —— 透明台标能不能看见全靠它', () {
      final plate = AppTokens.surfacePlate.computeLuminance();
      for (final (name, c) in _ladder) {
        if (name == 'surfacePlate') continue;
        expect(plate, greaterThan(c.computeLuminance()),
            reason: 'surfacePlate 必须比 $name 亮');
      }
    });

    test('相邻两级有可测差异(对比度 ≥ 1.08)', () {
      // 深色主题里相邻表面的亮度差本就很小(Material 深色高程叠加同量级)。
      // 这条只防阶梯塌陷,真正把卡片与背景分开的是描边 —— 见下面 line 的断言。
      for (var i = 1; i < _ladder.length; i++) {
        final (prevName, prev) = _ladder[i - 1];
        final (name, cur) = _ladder[i];
        final ratio = _contrast(cur, prev);
        expect(ratio, greaterThanOrEqualTo(1.08),
            reason: '$name 与 $prevName 对比度仅 ${ratio.toStringAsFixed(3)}');
      }
    });

    test('描边对每一级表面都可辨 —— 层次感实际靠它而非亮度差', () {
      for (final (name, surface) in _ladder) {
        if (identical(surface, AppTokens.line)) continue;
        final ratio = _contrast(AppTokens.line, surface);
        expect(ratio, greaterThanOrEqualTo(1.15),
            reason: '描边在 $name 上仅 ${ratio.toStringAsFixed(3)},卡片边界糊掉');
      }
    });

    test('中性色带冷偏 —— 蓝通道高于红通道,而非纯灰', () {
      for (final (name, c) in _ladder) {
        expect(c.b, greaterThan(c.r),
            reason: '$name 是纯灰或暖色,读起来像没选过色');
      }
    });
  });

  group('文字对比度', () {
    test('正文对每一级表面都达 AA(≥ 4.5:1)', () {
      for (final (name, surface) in _ladder) {
        final ratio = _contrast(AppTokens.textPrimary, surface);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: '正文在 $name 上仅 ${ratio.toStringAsFixed(2)}:1');
      }
    });

    test('次要文字对每一级表面都达 AA(≥ 4.5:1)', () {
      for (final (name, surface) in _ladder) {
        final ratio = _contrast(AppTokens.textSecondary, surface);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: '次要文字在 $name 上仅 ${ratio.toStringAsFixed(2)}:1');
      }
    });

    test('三级文字至少达非文本组件底线(≥ 3:1)', () {
      // 三级文字只用于等宽副行这类非关键信息,不强求 AA,
      // 但也不能低到看不见。
      for (final (name, surface) in _ladder) {
        final ratio = _contrast(AppTokens.textTertiary, surface);
        expect(ratio, greaterThanOrEqualTo(3.0),
            reason: '三级文字在 $name 上仅 ${ratio.toStringAsFixed(2)}:1');
      }
    });

    test('文字层级亮度依次递减,不出现倒挂', () {
      final p = AppTokens.textPrimary.computeLuminance();
      final s = AppTokens.textSecondary.computeLuminance();
      final t = AppTokens.textTertiary.computeLuminance();
      final d = AppTokens.textDisabled.computeLuminance();
      expect(p, greaterThan(s));
      expect(s, greaterThan(t));
      expect(t, greaterThan(d));
    });
  });

  group('源状态语义色', () {
    test('两个状态色在频道牌衬底上都够显眼(≥ 3:1)', () {
      // 它们是压在牌面上的小圆点,是唯一的异常线索,发闷就等于没有。
      for (final (name, c) in [
        ('sourceDead', AppTokens.sourceDead),
        ('sourceSlow', AppTokens.sourceSlow),
      ]) {
        final ratio = _contrast(c, AppTokens.surfacePlate);
        expect(ratio, greaterThanOrEqualTo(3.0),
            reason: '$name 在牌面上仅 ${ratio.toStringAsFixed(2)}:1');
      }
    });

    test('两个状态色彼此可区分 —— 否则「失效」和「慢」看着一样', () {
      final ratio = _contrast(AppTokens.sourceDead, AppTokens.sourceSlow);
      expect(ratio, greaterThanOrEqualTo(1.5),
          reason: '失效与响应慢对比度仅 ${ratio.toStringAsFixed(2)},分不出来');
    });
  });

  group('不透明性', () {
    test('参与对比度计算的令牌必须全不透明', () {
      // computeLuminance 无视 alpha,半透明令牌会虚报对比度,
      // 让上面所有断言失去意义(参见 app_palette_test 里的同类护栏)。
      final opaque = <String, Color>{
        'surfaceGround': AppTokens.surfaceGround,
        'surfaceDefault': AppTokens.surfaceDefault,
        'surfaceRaised': AppTokens.surfaceRaised,
        'surfacePlate': AppTokens.surfacePlate,
        'line': AppTokens.line,
        'textPrimary': AppTokens.textPrimary,
        'textSecondary': AppTokens.textSecondary,
        'textTertiary': AppTokens.textTertiary,
        'textDisabled': AppTokens.textDisabled,
        'sourceDead': AppTokens.sourceDead,
        'sourceSlow': AppTokens.sourceSlow,
      };
      opaque.forEach((name, c) {
        expect(c.a, 1.0, reason: '$name 带 alpha,对比度断言会失真');
      });
    });
  });

  group('兼容性', () {
    test('surfacePanel 仍可用,且已并入表面阶梯', () {
      // 它是旧调用点的名字,保留以免一次性改动过大;
      // 取值必须跟阶梯一致,否则又会分裂出第二套配色。
      expect(AppTokens.surfacePanel, AppTokens.surfaceDefault);
    });
  });
}
