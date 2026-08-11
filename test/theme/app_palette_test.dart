import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/shared/theme/app_palette.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// WCAG 对比度公式:(较亮亮度 + 0.05) / (较暗亮度 + 0.05)
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  group('AppPalette', () {
    test('每个预设色对深色面板的对比度 ≥ 3:1(WCAG 非文本 UI 组件底线)', () {
      // 主色驱动 TV 焦点环。对比度不足时焦点在深色面板上会发闷,
      // 用户看不出选中了哪一项 —— 这条断言就是防止色板混进暗色。
      for (final c in AppPalette.all) {
        final ratio = _contrast(c, AppTokens.surfacePanel);
        expect(ratio, greaterThanOrEqualTo(3.0),
            reason: '$c 对比度仅 ${ratio.toStringAsFixed(2)},'
                'TV 焦点环会在 #222 面板上发闷');
      }
    });

    test('色板无重复色', () {
      expect(AppPalette.all.toSet().length, AppPalette.all.length);
    });

    test('默认色仍是原品牌色 #00DC82,老用户升级后观感不变', () {
      expect(AppPalette.all.first, AppPalette.green);
      expect(AppPalette.green, const Color(0xFF00DC82));
    });

    test('色板恰好 8 色(UI 按 4x2 网格布局)', () {
      expect(AppPalette.all, hasLength(8));
    });

    test('预设色必须全不透明(computeLuminance 无视 alpha,半透明会虚报对比度)', () {
      // 实测:Color(0x40E91E63) 能以 3.66 通过上面的对比度断言,
      // 但它叠加到 #222222 上的真实对比度只有 1.24。
      for (final c in AppPalette.all) {
        expect(c.a, 1.0, reason: '$c 带 alpha,对比度断言会失真');
      }
    });
  });
}
