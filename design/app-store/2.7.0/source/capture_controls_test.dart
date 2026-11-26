import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/widgets/player_actions_widget.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/shared/theme/app_theme.dart';

import '../../../../test/mini/_fake_backend.dart';

const source = 'design/app-store/2.7.0/source';
const output = 'build/app-store/2.7.0/controls';

class PlayingSample extends FakeBackend {
  @override
  final notifier = ValueNotifier(
    const XPlayerValue(
      isInitialized: true,
      isPlaying: true,
      size: Size(1920, 1080),
    ),
  );
}

Future<void> registerFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        jsonDecode(await config.readAsString())['packages'] as List;
    final flutter = packages.singleWhere(
      (package) => package['name'] == 'flutter',
    );
    final sdk = Directory.fromUri(
      config.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    final fonts = '${sdk.path}/bin/cache/artifacts/material_fonts';
    await registerFont('MaterialIcons', ['$fonts/MaterialIcons-Regular.otf']);
    await registerFont('StoreLatin', [
      '$fonts/Roboto-Regular.ttf',
      '$fonts/Roboto-Medium.ttf',
    ]);
    await registerFont('StoreChinese', [
      '$source/fonts/NotoSansSC-400.ttf',
      '$source/fonts/NotoSansSC-600.ttf',
    ]);
    await Directory(output).create(recursive: true);
  });

  for (final language in ['en', 'zh']) {
    testWidgets('Capture the 2.7.0 player actions in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final capture = GlobalKey();
      final theme = buildAppTheme();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MediaProvider()),
            ChangeNotifierProvider(create: (_) => GlobalProvider()),
          ],
          child: MaterialApp(
            theme: theme.copyWith(
              textTheme: theme.textTheme.apply(
                fontFamily: language == 'zh' ? 'StoreChinese' : 'StoreLatin',
                fontFamilyFallback: const ['StoreLatin', 'StoreChinese'],
              ),
            ),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Material(
              type: MaterialType.transparency,
              child: RepaintBoundary(
                key: capture,
                child: PlayerActionsWidget(
                  channel: Channel(
                    id: '01',
                    name: language == 'en' ? 'Coast' : '海岸',
                    source: const [],
                  ),
                  backend: PlayingSample(),
                  onPlayPause: (_) {},
                  onFavorite: () async {},
                  favoriteChannels: const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final buttons = find.byType(XIconButton);
      final labels = tester
          .widgetList<XIconButton>(buttons)
          .take(3)
          .map((button) => button.label);
      expect(
        labels,
        language == 'en'
            ? ['Pause', 'Favorite', 'Channel List']
            : ['暂停', '收藏', '频道列表'],
      );
      final first = tester.getRect(buttons.at(0));
      final third = tester.getRect(buttons.at(2));
      final area = Rect.fromLTRB(
        first.left - 4,
        first.top - 4,
        third.right + 4,
        third.bottom + 4,
      );
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final layer = boundary.debugLayer! as OffsetLayer;
      await tester.runAsync(() async {
        final image = await layer.toImage(area, pixelRatio: 8);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          await File('$output/controls-$language.png').writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        } finally {
          image.dispose();
        }
      });
    });
  }
}
