import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_ui_gallery/main.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(1194, 834),
    const Size(1440, 960),
    const Size(1920, 1080)
  ]) {
    testWidgets('组件目录在 ${size.width.toInt()} 宽度的七个分类正常渲染', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ComponentGallery());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final density = size.width < 600
          ? '手机'
          : size.width < 1200
              ? 'iPad'
              : size.width < 1800
                  ? '桌面'
                  : 'TV';
      await tester.tap(find.widgetWithText(TextButton, density).first);
      await tester.pumpAndSettle();
      for (final label in [
        '基础操作',
        '频道与内容',
        '节目单',
        '播放控制',
        '列表与遥控',
        '边界状态',
        '设计总览'
      ]) {
        final target = find.widgetWithText(TextButton, label).first;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${size.width} $label');
      }
    });
  }
}
