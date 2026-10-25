import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/main.dart' as app;
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/data/repositories/favorites_repository.dart';
import 'package:xplayer/data/repositories/recent_repository.dart';
import 'package:xplayer/presentation/screens/home.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/presentation/widgets/operation_hint_dialog.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/shared/navigation.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

// 使用 Flutter 测试输入通道避免系统输入法回传旧编辑值；应用、网络、数据库和播放均为真实实现。
class _V3Binding extends IntegrationTestWidgetsFlutterBinding {
  @override
  bool get registerTestTextInput => true;
}

void main() {
  final binding = _V3Binding();
  const device = String.fromEnvironment('QA_DEVICE', defaultValue: 'phone');
  const base = String.fromEnvironment('QA_BASE_URL');
  Future<void> mode(String value) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$base/mode?epg=$value'));
      await (await request.close()).drain<void>();
    } finally {
      client.close();
    }
  }

  testWidgets('v3 真实应用导入、筛选、收藏、节目单与播放续播', (tester) async {
    expect(
      base,
      isNotEmpty,
      reason: '需要启动 tool/v3_fixture_server.py 并传入 QA_BASE_URL',
    );
    final steps = <String>[];
    Future<void> until(bool Function() ready, {int seconds = 40}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(ready(), isTrue, reason: '等待条件超时，最近步骤：$steps');
    }

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 350));
      await binding.takeScreenshot('$device-$name');
    }

    Future<void> nav(String name) async {
      final target = find.byKey(ValueKey('nav-$name'));
      await tester.ensureVisible(target);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 350));
    }

    final prefs = await SharedPreferences.getInstance();
    // 仅针对本轮创建的专用模拟器运行；清理的是该模拟器的验收应用数据。
    await prefs.clear();
    await prefs.setBool('seeded_default_preset', true);
    await prefs.setBool('auto_refresh_channels', false);
    await prefs.setBool('auto_refresh_programmes', false);
    await prefs.setString('language_code', 'zh');
    final repository = PlaylistRepository();
    for (final playlist in await repository.getAllPlaylists()) {
      await repository.deletePlaylist(playlist.id!);
    }
    final favorites = FavoritesRepository();
    for (final channel in await favorites.getAllFavorites()) {
      await favorites.removeFavorite(channel.id);
    }
    await RecentRepository().clearRecent();
    await loadMiniPlayerSetting();
    await loadNativeEngineMode();
    await loadPipSetting();
    await mode('normal');
    await tester.pumpWidget(app.createApplication());
    await until(() => find.byType(HomeScreen).evaluate().isNotEmpty);
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    await shot('empty');
    debugPrint('V3 checkpoint: ${steps.length}');
    steps.add('专用模拟器以真实空数据库启动');
    await tester.tap(find.byTooltip('添加播放列表'));
    await tester.pump(const Duration(milliseconds: 500));
    Finder input(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextField),
    );
    await tester.enterText(input('playlist-name'), 'V3 验收来源');
    await tester.enterText(input('playlist-url'), 'invalid-address');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(TextButton, '新增'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('请输入有效的 http / https 地址，或选择本地 M3U 文件。'), findsOneWidget);
    expect(
      tester.widget<TextField>(input('playlist-url')).controller!.text,
      'invalid-address',
    );
    debugPrint('V3 checkpoint: ${steps.length}');
    steps.add('非法列表地址保留输入并阻止提交');
    await tester.tap(input('playlist-url'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.enterText(input('playlist-url'), '$base/live.m3u');
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<TextField>(input('playlist-url')).controller!.text,
      '$base/live.m3u',
    );
    debugPrint(
      'V3 valid URL: ${tester.widget<TextField>(input('playlist-url')).controller!.text}',
    );
    await tester.ensureVisible(find.widgetWithText(TextButton, '新增'));
    await tester.tap(find.widgetWithText(TextButton, '新增'));
    await shot('submitted-dialog');
    debugPrint(
      'V3 route: home=${find.byType(HomeScreen).evaluate().length} add=${find.byTooltip('添加播放列表').evaluate().length} form=${find.byKey(const Key('playlist-name')).evaluate().length}',
    );
    await until(
      () =>
          find.byType(HomeScreen).evaluate().isNotEmpty &&
          find.byTooltip('添加播放列表').evaluate().isNotEmpty &&
          find.byKey(const Key('playlist-name')).evaluate().isEmpty,
    );
    final homeContext = tester.element(find.byType(HomeScreen));
    final media = homeContext.read<MediaProvider>();
    await until(
      () => media.channels.length == 3 && media.programmes.isNotEmpty,
    );
    expect(media.currentPlaylist.epgUrl, '$base/guide.xml');
    debugPrint('V3 checkpoint: ${steps.length}');
    steps.add('M3U 与文件头 XMLTV 通过现有仓库真实导入');
    await shot('home');
    await nav('channels');
    final search = find.descendant(
      of: find.byType(XpSearchField),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, '一台');
    await tester.pump(const Duration(milliseconds: 500));
    expect(media.filteredChannels.single.id.toLowerCase(), 'qa-one');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    final favorite = find.byTooltip('收藏 验收一台');
    await tester.ensureVisible(favorite);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(favorite);
    await until(() => media.favoriteChannels.length == 1);
    debugPrint('V3 checkpoint: ${steps.length}');
    steps.add('搜索与收藏写入真实 Provider 和数据库');
    await shot('channels');
    await nav('favorites');
    expect(find.byTooltip('取消收藏 验收一台'), findsOneWidget);
    await shot('favorites');
    await nav('guide');
    await shot('guide');
    await mode('error');
    await media.refreshProgrammes();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('更新失败，继续显示已有节目单'), findsOneWidget);
    debugPrint('V3 checkpoint: ${steps.length}');
    steps.add('EPG 503 保留当前有效缓存');
    await shot('epg-error-cache');
    await mode('stale');
    await media.refreshProgrammes();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('这份节目单已经过期'), findsOneWidget);
    debugPrint('V3 checkpoint: ${steps.length}');
    steps.add('过期节目单保留参考，移除当前播出语义');
    await shot('epg-stale');
    await mode('normal');
    await media.refreshProgrammes();
    await nav('channels');
    final card = find.byKey(
      ValueKey('channel-${media.filteredChannels.single.id}'),
    );
    await tester.ensureVisible(card);
    await tester.pump(const Duration(milliseconds: 400));
    final play = find
        .descendant(of: card, matching: find.byType(InkWell))
        .first;
    await tester.tap(play);
    await until(() => find.byType(PlayerScreen).evaluate().isNotEmpty);
    final mini = AppNav.key.currentContext!.read<MiniPlayerController>();
    await until(
      () =>
          mini.backend?.notifier.value.isInitialized == true &&
          mini.backend?.notifier.value.isPlaying == true,
      seconds: 45,
    );
    final hint = find.byType(OperationHintDialog);
    if (hint.evaluate().isNotEmpty) {
      final label = AppLocalizations.of(tester.element(hint))!.hintGotIt;
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 500));
      steps.add('首次播放帮助可关闭');
    }
    final backend = mini.backend!;
    final initial = backend.notifier.value;
    expect(initial.size.width, greaterThan(0));
    await until(() => backend.notifier.value.position > initial.position);
    debugPrint('V3 checkpoint: ${steps.length}');
    steps.add('实际播放器初始化、出视频尺寸且播放位置推进');
    await shot('player');
    await tester.tap(find.byTooltip('返回频道'));
    await until(() => mini.hasMini);
    await until(() => find.byType(PlayerScreen).evaluate().isEmpty);
    expect(identical(mini.backend, backend), isTrue);
    debugPrint('V3 checkpoint: ${steps.length}');
    steps.add('返回频道复用同一后端进入小窗');
    await shot('mini');
    await mini.close();
    await tester.pump(const Duration(milliseconds: 500));
    await nav('settings');
    await shot('settings');
    expect(tester.takeException(), isNull);
    binding.reportData ??= {};
    binding.reportData!.addAll({
      'device': device,
      'passed': true,
      'isTv': homeContext.read<GlobalProvider>().isTV,
      'size': '${tester.view.physicalSize}',
      'pixelRatio': tester.view.devicePixelRatio,
      'backend': '${backend.runtimeType}',
      'videoWidth': initial.size.width,
      'videoHeight': initial.size.height,
      'steps': steps,
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
