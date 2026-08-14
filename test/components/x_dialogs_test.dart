import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/shared/components/x_dialog_shell.dart';

Future<void> _open(WidgetTester tester, Widget Function(BuildContext) build,
    {bool form = false}) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('zh')],
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              if (form) {
                XFormDialog.show(context, build(context));
              } else {
                showDialog(context: context, builder: (_) => build(context));
              }
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('XFormDialog 表单类', () {
    testWidgets('主操作用调用方给的动词,而非「确定」', (tester) async {
      await _open(
        tester,
        (_) => XFormDialog(
          title: '添加播放列表',
          actionLabel: '添加',
          onAction: () {},
          child: const SizedBox(height: 40),
        ),
        form: true,
      );
      expect(find.text('添加'), findsOneWidget);
      // 「确定」不告诉用户会发生什么,表单类不该出现它。
      expect(find.text('确定'), findsNothing);
    });

    testWidgets('有取消键', (tester) async {
      await _open(
        tester,
        (_) => XFormDialog(
          title: 'T',
          actionLabel: '保存',
          onAction: () {},
          child: const SizedBox(height: 40),
        ),
        form: true,
      );
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('点遮罩不关闭 —— 填了半天手滑点到外面不该全没了', (tester) async {
      await _open(
        tester,
        (_) => XFormDialog(
          title: '添加播放列表',
          actionLabel: '添加',
          onAction: () {},
          child: const SizedBox(height: 40),
        ),
        form: true,
      );
      // 点弹窗外部
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('添加播放列表'), findsOneWidget);
    });

    testWidgets('onAction 为 null 时主按钮置灰而非隐藏', (tester) async {
      await _open(
        tester,
        (_) => const XFormDialog(
          title: 'T',
          actionLabel: '添加',
          onAction: null,
          child: SizedBox(height: 40),
        ),
        form: true,
      );
      // 按钮仍在:让用户看得见有这个操作,只是现在还不能按。
      expect(find.text('添加'), findsOneWidget);
    });

    testWidgets('leading 放在左侧,与右侧取消/主操作分开', (tester) async {
      await _open(
        tester,
        (_) => XFormDialog(
          title: 'T',
          actionLabel: '添加',
          onAction: () {},
          leading: const Text('从预置源选择'),
          child: const SizedBox(height: 40),
        ),
        form: true,
      );
      final leadX = tester.getCenter(find.text('从预置源选择')).dx;
      final actionX = tester.getCenter(find.text('添加')).dx;
      expect(leadX, lessThan(actionX));
    });
  });

  group('XPickerDialog 选择类', () {
    testWidgets('默认没有任何按钮 —— 点选项本身就是提交', (tester) async {
      await _open(
        tester,
        (_) => const XPickerDialog(
          title: '画质',
          child: SizedBox(height: 40),
        ),
      );
      expect(find.text('确定'), findsNothing);
      expect(find.text('取消'), findsNothing);
    });

    testWidgets('需要即时预览时可给一个完成键(如主题色)', (tester) async {
      await _open(
        tester,
        (_) => const XPickerDialog(
          title: '主题色',
          doneLabel: '完成',
          child: SizedBox(height: 40),
        ),
      );
      expect(find.text('完成'), findsOneWidget);
    });

    testWidgets('点遮罩可关闭', (tester) async {
      await _open(
        tester,
        (_) => const XPickerDialog(title: '画质', child: SizedBox(height: 40)),
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('画质'), findsNothing);
    });
  });

  group('XConfirmDialog 确认类', () {
    testWidgets('危险动作用动词,并有取消键', (tester) async {
      await _open(
        tester,
        (_) => XConfirmDialog(
          title: '移除「朋友分享的源」？',
          description: '这个源提供的 96 个频道会从列表中消失,其中 4 个在你的收藏里。',
          actionLabel: '移除',
          onAction: () {},
        ),
      );
      expect(find.text('移除'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('说明写具体后果,而不是「此操作不可撤销」这种空话', (tester) async {
      await _open(
        tester,
        (_) => XConfirmDialog(
          title: 'T',
          description: '这个源提供的 96 个频道会从列表中消失,其中 4 个在你的收藏里。',
          actionLabel: '移除',
          onAction: () {},
        ),
      );
      expect(find.textContaining('96 个频道'), findsOneWidget);
      expect(find.textContaining('4 个在你的收藏里'), findsOneWidget);
    });

    testWidgets('按危险动作会触发回调并关闭', (tester) async {
      var fired = false;
      await _open(
        tester,
        (_) => XConfirmDialog(
          title: '移除？',
          description: 'D',
          actionLabel: '移除',
          onAction: () => fired = true,
        ),
      );
      await tester.tap(find.text('移除'));
      await tester.pumpAndSettle();
      expect(fired, isTrue);
      expect(find.text('移除？'), findsNothing);
    });

    testWidgets('按取消不触发回调', (tester) async {
      var fired = false;
      await _open(
        tester,
        (_) => XConfirmDialog(
          title: '移除？',
          description: 'D',
          actionLabel: '移除',
          onAction: () => fired = true,
        ),
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(fired, isFalse);
    });

    testWidgets('点遮罩＝取消,不触发回调', (tester) async {
      var fired = false;
      await _open(
        tester,
        (_) => XConfirmDialog(
          title: '移除？',
          description: 'D',
          actionLabel: '移除',
          onAction: () => fired = true,
        ),
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(fired, isFalse);
      expect(find.text('移除？'), findsNothing);
    });
  });
}
