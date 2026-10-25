import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/main.dart' as app;
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/presentation/adapters/media_presentation.dart';
import 'package:xplayer/presentation/screens/home.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/presentation/widgets/operation_hint_dialog.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/shared/navigation.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

class _LanBinding extends IntegrationTestWidgetsFlutterBinding {
  @override
  bool get registerTestTextInput => true;
}

void main() {
  final binding = _LanBinding();
  const source = String.fromEnvironment('QA_PLAYLIST_URL');
  const channelName = String.fromEnvironment(
    'QA_CHANNEL_NAME',
    defaultValue: 'CCTV-1',
  );
  const device = String.fromEnvironment('QA_DEVICE', defaultValue: 'phone');
  testWidgets('v3 用户局域网来源导入、节目单状态、真实直播与续播', (tester) async {
    expect(source, isNotEmpty);
    Future<void> until(bool Function() ready, {int seconds = 60}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(ready(), isTrue, reason: '局域网验证等待超时');
    }

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      await binding.takeScreenshot('$device-lan-$name');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seeded_default_preset', true);
    await prefs.setBool('auto_refresh_channels', false);
    await prefs.setBool('auto_refresh_programmes', false);
    await prefs.setString('language_code', 'zh');
    final repository = PlaylistRepository();
    for (final list in await repository.getAllPlaylists()) {
      if (list.url == source) await repository.deletePlaylist(list.id!);
    }
    await prefs.setString('lastSelectedPlaylistId', '-1');
    await loadMiniPlayerSetting();
    await loadNativeEngineMode();
    await tester.pumpWidget(app.createApplication());
    await until(() => find.byType(HomeScreen).evaluate().isNotEmpty);
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    await tester.tap(find.byTooltip('添加播放列表'));
    await tester.pump(const Duration(milliseconds: 400));
    Finder input(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextField),
    );
    await tester.enterText(input('playlist-name'), '局域网播放列表');
    await tester.enterText(input('playlist-url'), source);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 400));
    final add = find.widgetWithText(TextButton, '新增');
    await tester.ensureVisible(add);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(add);
    final home = tester.element(find.byType(HomeScreen));
    final media = home.read<MediaProvider>();
    await until(
      () => media.currentPlaylist.url == source && media.channels.length > 10,
    );
    await until(() {
      final url = media.currentPlaylist.epgUrl;
      return !media.isRefreshingProgrammes &&
          (url == null ||
              url.isEmpty ||
              media.epgSnapshots.containsKey(url) ||
              media.epgErrors.containsKey(url));
    }, seconds: 90);
    final epg = MediaPresentation(media);
    await shot('home');
    await tester.tap(find.byKey(const ValueKey('nav-guide')));
    await tester.pump(const Duration(milliseconds: 500));
    await shot('guide');
    await tester.tap(find.byKey(const ValueKey('nav-channels')));
    await tester.pump(const Duration(milliseconds: 500));
    final search = find.descendant(
      of: find.byType(XpSearchField),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, channelName);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    final channel = media.filteredChannels.firstWhere(
      (c) => c.name == channelName,
    );
    final card = find.byKey(ValueKey('channel-${channel.id}'));
    await tester.ensureVisible(card);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(
      find.descendant(of: card, matching: find.byType(InkWell)).first,
    );
    await until(() => find.byType(PlayerScreen).evaluate().isNotEmpty);
    final mini = AppNav.key.currentContext!.read<MiniPlayerController>();
    await until(
      () =>
          mini.backend?.notifier.value.isPlaying == true &&
          (mini.backend?.notifier.value.size.width ?? 0) > 0,
      seconds: 90,
    );
    final hint = find.byType(OperationHintDialog);
    if (hint.evaluate().isNotEmpty) {
      await tester.tap(
        find.text(AppLocalizations.of(tester.element(hint))!.hintGotIt),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
    final backend = mini.backend!;
    final value = backend.notifier.value;
    await until(() => backend.notifier.value.position > value.position);
    await shot('playing');
    await tester.tap(find.byTooltip('返回频道'));
    await until(
      () => mini.hasMini && find.byType(PlayerScreen).evaluate().isEmpty,
    );
    expect(identical(mini.backend, backend), isTrue);
    await shot('mini');
    await mini.close();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    binding.reportData ??= {};
    binding.reportData!.addAll({
      'device': '$device-lan',
      'passed': true,
      'channels': media.channels.length,
      'programmes': epg.relevantProgrammes.length,
      'epgStatus': epg.epgStatus.name,
      'coverageEnd': epg.coverageEnd?.toIso8601String(),
      'channel': channel.name,
      'backend': '${backend.runtimeType}',
      'videoWidth': value.size.width,
      'videoHeight': value.size.height,
      'sameBackendInMini': true,
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
