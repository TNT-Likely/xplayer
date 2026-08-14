import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/components/channel_plate.dart';

/// 频道卡片的高度预算护栏。
///
/// 真机上报过 `RenderFlex overflowed by 15 pixels on the bottom`，根因是
/// 牌面从 16:9 改成 16:10 吃掉了标题区，而标题同时从单行变成两行 + 副行。
/// 两处改动叠加，网格 `childAspectRatio: 16/12` 留下的空间就不够了。
///
/// 这里不去渲染整张卡（它依赖 Provider / 路由），而是直接验证几何约束：
/// **牌面高度 + 文字高度 ≤ 卡片高度**。算术护栏比 widget 树更能说清为什么。
void main() {
  /// 与 channel_list_widget 保持一致。改那边必须同步改这里，否则护栏失效。
  const cardAspect = 16 / 15;

  /// 与 channel_item_widget 保持一致。
  const nameFontFactor = 0.07;
  const nameLineHeight = 1.25;
  const subFontFactor = 0.055;
  const subLineHeight = 1.2;

  /// 上下内边距各 0.03W。按比例而非固定值 —— 固定值在窄卡片上占比过大，
  /// 会把按比例算出来的高度预算挤爆。
  const verticalPaddingFactor = 0.06;

  double plateHeight(double w) => w * 10 / 16; // ChannelPlate 固定 16:10
  double cardHeight(double w) => w / cardAspect;

  double textHeight(double w, {required int nameLines, required bool hasSub}) {
    final name = w * nameFontFactor * nameLineHeight * nameLines;
    final sub = hasSub ? w * subFontFactor * subLineHeight : 0.0;
    return name + sub + w * verticalPaddingFactor;
  }

  group('卡片高度预算', () {
    // 覆盖真实网格里会出现的宽度区间:手机 3 列到桌面多列。
    const widths = [80.0, 100.0, 120.0, 148.0, 180.0, 240.0];

    test('单行名称 + 副行放得下', () {
      for (final w in widths) {
        final need = plateHeight(w) + textHeight(w, nameLines: 1, hasSub: true);
        expect(need, lessThanOrEqualTo(cardHeight(w)),
            reason: '宽 $w 时需要 ${need.toStringAsFixed(1)}，'
                '卡片只有 ${cardHeight(w).toStringAsFixed(1)}');
      }
    });

    test('两行名称 + 副行放得下 —— 长频道名会换行', () {
      for (final w in widths) {
        final need = plateHeight(w) + textHeight(w, nameLines: 2, hasSub: true);
        expect(need, lessThanOrEqualTo(cardHeight(w)),
            reason: '宽 $w 时需要 ${need.toStringAsFixed(1)}，'
                '卡片只有 ${cardHeight(w).toStringAsFixed(1)}');
      }
    });

    test('旧比例 16/12 装不下当前内容 —— 记录这次回归的成因', () {
      // 这条不是在测当前代码，而是把「为什么必须改比例」钉住:
      // 换牌面比例时若忘了同步网格，就会退回这个状态。
      const oldAspect = 16 / 12;
      const w = 120.0;
      final need = plateHeight(w) + textHeight(w, nameLines: 1, hasSub: true);
      expect(need, greaterThan(w / oldAspect),
          reason: '旧比例本应装不下，若此断言失败说明几何参数已变，'
              '需重新核对 channel_list_widget 的 childAspectRatio');
    });
  });

  group('ChannelPlate 几何', () {
    testWidgets('牌面确实是 16:10，与上面的预算一致', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              child: ChannelPlate(
                channel: Channel(
                  id: 'X',
                  name: 'CCTV-1 综合',
                  source: [
                    Source(
                      title: 't',
                      link: 'http://a/x.m3u8',
                      groupTitle: 'News',
                      attributes: const {},
                      duration: -1,
                    )
                  ],
                ),
                width: 120,
              ),
            ),
          ),
        ),
      ));
      final size = tester.getSize(find.byType(AspectRatio));
      expect(size.width / size.height, closeTo(16 / 10, 0.01));
    });
  });
}
