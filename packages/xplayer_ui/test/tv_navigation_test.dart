import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

Widget host(Widget child) {
  const theme = XpThemeData(device: XpDevice.tv);
  return XpTheme(
      data: theme,
      child: MaterialApp(
          theme: theme.materialTheme(), home: Scaffold(body: child)));
}

void main() {
  testWidgets('TV 收藏向下到播放，左右切换节目详情，并能确认', (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var played = 0, details = 0;
    final now = DateTime(2026, 10, 25, 22);
    await tester.pumpWidget(host(SingleChildScrollView(
        child: Column(children: [
      XpButton(label: '上方操作', onPressed: () {}),
      XpFeaturedChannel(
          compact: true,
          now: now,
          channel: XpChannelData(
              id: 'one',
              name: '测试频道',
              programme: XpProgramme(
                  title: '正在播放',
                  start: now.subtract(const Duration(minutes: 10)),
                  end: now.add(const Duration(minutes: 20)))),
          onFavouriteChanged: (_) {},
          onPlay: () => played++,
          onDetails: () => details++),
      XpButton(label: '下方操作', onPressed: () {}),
    ]))));
    await tester.pumpAndSettle();
    final favourite = tester
        .widget<XpFavouriteButton>(find.byType(XpFavouriteButton))
        .focusNode!;
    FocusNode button(String label) => tester
        .widget<XpButton>(find.widgetWithText(XpButton, label))
        .focusNode!;
    favourite.requestFocus();
    await tester.pump();
    final originalPlayTop =
        tester.getTopLeft(find.widgetWithText(XpButton, '立即观看')).dy;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(button('立即观看').hasPrimaryFocus, isTrue);
    expect(tester.getTopLeft(find.widgetWithText(XpButton, '立即观看')).dy,
        closeTo(originalPlayTop, 1),
        reason: '操作已经可见时不应把页面滚到顶部');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(button('节目详情').hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(details, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(button('立即观看').hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(played, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(favourite.hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TV 搜索浏览不弹输入，确认编辑，方向键及返回均可退出并保留关键词', (tester) async {
    final controller = TextEditingController();
    final search = FocusNode(),
        before = FocusNode(),
        after = FocusNode(),
        side = FocusNode();
    addTearDown(controller.dispose);
    for (final node in [search, before, after, side]) {
      addTearDown(node.dispose);
    }
    await tester.pumpWidget(host(Row(children: [
      SizedBox(
          width: 120,
          child: XpButton(label: '侧栏', focusNode: side, onPressed: () {})),
      Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        XpButton(label: '上方', focusNode: before, onPressed: () {}),
        XpSearchField(
            controller: controller, focusNode: search, onChanged: (_) {}),
        XpButton(label: '下方', focusNode: after, onPressed: () {}),
      ])),
    ])));
    search.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(after.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(search.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final editor =
        tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    expect(editor.hasPrimaryFocus, isTrue);
    await tester.enterText(find.byType(TextField), 'CCTV');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(after.hasPrimaryFocus, isTrue);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(controller.text, 'CCTV');
    search.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(side.hasPrimaryFocus, isTrue);
    expect(controller.text, 'CCTV');
    search.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(search.hasPrimaryFocus, isTrue);
    expect(controller.text, 'CCTV');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    addTearDown(tester.view.resetViewInsets);
    tester.view.viewInsets = FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(search.hasPrimaryFocus, isTrue, reason: '系统收起软键盘后恢复方向导航');
    expect(controller.text, 'CCTV');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(side.hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
