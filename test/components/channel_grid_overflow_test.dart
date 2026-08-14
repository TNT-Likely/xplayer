import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/components/channel_plate.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 频道卡片布局护栏。
///
/// 真机连报两次 `RenderFlex overflowed`，根因都是「牌面比例」与
/// 「网格比例」这两个数字被单独改动，标题区被挤没了。
///
/// 这里直接搭一个和 `channel_item_widget` 同构的最小卡片去渲染，
/// 而不是用算术推演——上一版护栏就是算术推的，参数一对不上就形同虚设。
void main() {
  /// 与 channel_list_widget 保持一致。
  const gridAspect = 16 / 12;

  late List<String> overflows;

  /// 与 channel_item_widget 的标题区同构：牌面 + 自适应文字区。
  Widget buildCard(double w, {required String name, required String sub}) {
    return SizedBox(
      width: w,
      height: w / gridAspect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChannelPlate(
            channel: Channel(
              id: 'X',
              name: name,
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
            width: w,
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: w * 0.015, horizontal: w * 0.06),
              child: LayoutBuilder(
                builder: (context, c) {
                  final nameH = w * 0.07 * 1.25;
                  final subH = w * 0.055 * 1.2;
                  final showSub = sub.isNotEmpty && c.maxHeight >= nameH + subH;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: Text(name,
                            textAlign: TextAlign.center,
                            maxLines: showSub ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: w * 0.07,
                                height: 1.25,
                                color: AppTokens.textPrimary)),
                      ),
                      if (showSub)
                        Flexible(
                          child: Text(sub,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: w * 0.055,
                                  height: 1.2,
                                  color: AppTokens.textTertiary)),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    double w, {
    String name = 'CCTV-1 综合',
    String sub = '综合 · CN',
    double textScale = 1.0,
  }) async {
    overflows = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      final s = d.exceptionAsString();
      if (s.contains('overflowed')) {
        overflows.add(s);
      } else {
        prev?.call(d);
      }
    };
    addTearDown(() => FlutterError.onError = prev);

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(child: buildCard(w, name: name, sub: sub)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  void expectNoOverflow(double w) {
    expect(overflows, isEmpty,
        reason: '宽 $w 时溢出:\n${overflows.join("\n")}');
  }

  group('卡片不溢出', () {
    // 覆盖真实网格里会出现的宽度区间:手机多列到桌面大卡。
    const widths = [80.0, 100.0, 120.0, 148.0, 180.0, 240.0];

    testWidgets('常规名称 + 副行', (tester) async {
      for (final w in widths) {
        await pump(tester, w);
        expectNoOverflow(w);
      }
    });

    testWidgets('超长名称会换行,仍不溢出', (tester) async {
      for (final w in widths) {
        await pump(tester, w,
            name: '一个非常非常长的频道名称用来逼它换行看会不会溢出');
        expectNoOverflow(w);
      }
    });

    testWidgets('没有副行时也不溢出', (tester) async {
      for (final w in widths) {
        await pump(tester, w, sub: '');
        expectNoOverflow(w);
      }
    });

    testWidgets('文字放大 1.3 倍不溢出 —— 用户会调大系统字号', (tester) async {
      for (final w in widths) {
        await pump(tester, w, textScale: 1.3);
        expectNoOverflow(w);
      }
    });

    testWidgets('文字放大 1.6 倍不溢出', (tester) async {
      for (final w in widths) {
        await pump(tester, w, textScale: 1.6);
        expectNoOverflow(w);
      }
    });
  });

  group('几何约束', () {
    testWidgets('牌面默认 16:9 —— 与网格 16/12 的高度预算配套', (tester) async {
      await pump(tester, 120);
      final size = tester.getSize(find.byType(AspectRatio).first);
      expect(size.width / size.height, closeTo(16 / 9, 0.01),
          reason: '改牌面比例必须同步核对 channel_list_widget 的 childAspectRatio');
    });

    testWidgets('衬底是半透明的 —— 首页有背景图,卡片要透出底图', (tester) async {
      await pump(tester, 120);
      final box = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppTokens.surfaceThumb;
      });
      final d = box.decoration as BoxDecoration;
      expect(d.color!.a, lessThan(1.0),
          reason: '牌面刷成不透明会把背景图挡住,整屏变成实心色块');
    });
  });
}
