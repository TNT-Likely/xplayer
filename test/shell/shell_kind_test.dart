import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/presentation/shell/input_mode.dart';
import 'package:xplayer/presentation/shell/shell_kind.dart';

void main() {
  group('resolveShellFrom 纯判定', () {
    test('遥控器一律走 tenFoot,不管屏多宽', () {
      // 电视分辨率往往比桌面还大(1920/3840)。若按宽度判会归到 expanded,
      // 于是拿到一套需要鼠标悬停的界面 —— 遥控器没法用。这条就是防它。
      for (final w in [800.0, 1280.0, 1920.0, 3840.0]) {
        expect(resolveShellFrom(input: InputMode.remote, width: w),
            ShellKind.tenFoot,
            reason: '宽 $w 的电视被误判了');
      }
    });

    test('窄屏走 compact', () {
      expect(resolveShellFrom(input: InputMode.touch, width: 390),
          ShellKind.compact);
      expect(resolveShellFrom(input: InputMode.touch, width: 834),
          ShellKind.compact);
    });

    test('宽屏走 expanded', () {
      expect(resolveShellFrom(input: InputMode.pointer, width: 1280),
          ShellKind.expanded);
      expect(resolveShellFrom(input: InputMode.touch, width: 1194),
          ShellKind.expanded);
    });

    test('断点边界:恰好 1000 算 expanded', () {
      expect(resolveShellFrom(input: InputMode.touch, width: 999.9),
          ShellKind.compact);
      expect(resolveShellFrom(input: InputMode.touch, width: 1000),
          ShellKind.expanded);
    });

    test('触摸与指针在同宽度下骨架相同 —— 输入方式只影响密度与焦点表现', () {
      for (final w in [390.0, 1280.0]) {
        expect(resolveShellFrom(input: InputMode.touch, width: w),
            resolveShellFrom(input: InputMode.pointer, width: w));
      }
    });
  });

  group('InputMode 能力', () {
    test('只有指针有悬停态', () {
      expect(InputMode.pointer.hasHover, isTrue);
      expect(InputMode.touch.hasHover, isFalse);
      expect(InputMode.remote.hasHover, isFalse);
    });

    test('只有遥控器强制要求处处可聚焦', () {
      expect(InputMode.remote.needsFocusTraversal, isTrue);
      expect(InputMode.touch.needsFocusTraversal, isFalse);
      expect(InputMode.pointer.needsFocusTraversal, isFalse);
    });
  });

  group('InputModeScope', () {
    testWidgets('下游能取到注入的值', (tester) async {
      late InputMode got;
      await tester.pumpWidget(InputModeScope(
        mode: InputMode.remote,
        child: Builder(builder: (c) {
          got = InputModeScope.of(c);
          return const SizedBox();
        }),
      ));
      expect(got, InputMode.remote);
    });

    testWidgets('没有祖先 scope 时按平台兜底,不抛异常', (tester) async {
      late InputMode got;
      await tester.pumpWidget(Builder(builder: (c) {
        got = InputModeScope.of(c);
        return const SizedBox();
      }));
      expect(got, isA<InputMode>());
    });

    testWidgets('可在桌面强制切 tenFoot —— 不必每次往电视上装包才能调 TV 布局',
        (tester) async {
      late ShellKind kind;
      await tester.pumpWidget(MaterialApp(
        home: InputModeScope(
          mode: InputMode.remote,
          child: Builder(builder: (c) {
            kind = resolveShell(c);
            return const SizedBox();
          }),
        ),
      ));
      expect(kind, ShellKind.tenFoot);
    });
  });

  group('resolveShell 走 context', () {
    Future<ShellKind> pump(WidgetTester tester,
        {required InputMode mode, required double width}) async {
      late ShellKind kind;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: InputModeScope(
            mode: mode,
            child: Builder(builder: (c) {
              kind = resolveShell(c);
              return const SizedBox();
            }),
          ),
        ),
      ));
      return kind;
    }

    testWidgets('窄屏触摸 → compact', (tester) async {
      expect(await pump(tester, mode: InputMode.touch, width: 390),
          ShellKind.compact);
    });

    testWidgets('宽屏指针 → expanded', (tester) async {
      expect(await pump(tester, mode: InputMode.pointer, width: 1440),
          ShellKind.expanded);
    });

    testWidgets('遥控器 → tenFoot(宽度无关)', (tester) async {
      expect(await pump(tester, mode: InputMode.remote, width: 1920),
          ShellKind.tenFoot);
    });
  });

  group('channelCardWidth', () {
    test('三种骨架各有建议宽度,组件本身不分支只接参数', () {
      expect(channelCardWidth(ShellKind.compact, 390), 104);
      expect(channelCardWidth(ShellKind.compact, 834), 148); // iPad 竖屏放大
      expect(channelCardWidth(ShellKind.expanded, 1440), 132);
      expect(channelCardWidth(ShellKind.tenFoot, 1920), 118);
    });

    test('十英尺下卡片不小于手机 —— 观看距离远,不能更小', () {
      expect(channelCardWidth(ShellKind.tenFoot, 1920),
          greaterThanOrEqualTo(channelCardWidth(ShellKind.compact, 390)));
    });
  });
}
