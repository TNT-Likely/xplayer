import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';

void main() {
  Finder field(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );

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

      const values = {
        'playlist-name': '我的清单',
        'playlist-url': 'https://example.com/playlist.m3u',
        'playlist-epg': 'https://example.com/epg.xml',
      };
      for (final entry in values.entries) {
        final input = field(entry.key);
        await tester.ensureVisible(input);
        await tester.tap(input);
        await tester.pump();

        clipboard = entry.value;
        await pressCtrl(LogicalKeyboardKey.keyV);
        expect(tester.widget<TextField>(input).controller!.text, entry.value);

        clipboard = null;
        await pressCtrl(LogicalKeyboardKey.keyA);
        await pressCtrl(LogicalKeyboardKey.keyC);
        expect(clipboard, entry.value);
      }
    },
    variant: const TargetPlatformVariant({TargetPlatform.windows}),
  );

  testWidgets(
    'Android directional keys still move focus between the playlist fields',
    (tester) async {
      await showAddPlaylist(tester);
      FocusNode focusOf(String key) => tester
          .widget<EditableText>(
            find.descendant(
              of: field(key),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode;
      final name = focusOf('playlist-name');
      final url = focusOf('playlist-url');
      final localizations = AppLocalizations.of(
        tester.element(find.byType(PlaylistDialog)),
      )!;
      final picker = Focus.of(
        tester.element(find.text(localizations.pickLocalM3u)),
      );

      expect(name.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(url.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(picker.hasFocus, isTrue);

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
