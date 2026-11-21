import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';

void main() {
  Future<void> showAddPlaylist(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(),
      ),
    );
    showDialog<void>(
      context: tester.element(find.byType(Scaffold)),
      builder: (_) => const PlaylistDialog(isNew: true),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Windows playlist fields support keyboard copy and paste',
    (tester) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      String? clipboard;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            clipboard = (call.arguments as Map)['text'] as String?;
          case 'Clipboard.getData':
            return clipboard == null ? null : {'text': clipboard};
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await showAddPlaylist(tester);

      Future<void> pressCtrl(LogicalKeyboardKey key) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
      }

      final fields = find.byType(TextField);
      const values = ['我的清单', 'https://example.com/playlist.m3u'];
      for (var index = 0; index < values.length; index++) {
        final field = fields.at(index);
        final value = values[index];
        await tester.tap(field);
        await tester.pump();

        clipboard = value;
        await pressCtrl(LogicalKeyboardKey.keyV);
        expect(tester.widget<TextField>(field).controller!.text, value);

        clipboard = null;
        await pressCtrl(LogicalKeyboardKey.keyA);
        await pressCtrl(LogicalKeyboardKey.keyC);
        expect(clipboard, value);
      }
    },
    variant: const TargetPlatformVariant({TargetPlatform.windows}),
  );

  testWidgets(
    'Android directional keys still move focus between the playlist fields',
    (tester) async {
      await showAddPlaylist(tester);
      final fields = find.byType(TextField);
      final name = tester.widget<TextField>(fields.at(0)).focusNode!;
      final url = tester.widget<TextField>(fields.at(1)).focusNode!;

      expect(name.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(url.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(url.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(url.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(name.hasPrimaryFocus, isTrue);
    },
    variant: const TargetPlatformVariant({TargetPlatform.android}),
  );
}
