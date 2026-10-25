import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/main.dart' as app;
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/screens/home.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/presentation/widgets/channel_source_widget.dart';
import 'package:xplayer/presentation/widgets/channel_selector_widget.dart';
import 'package:xplayer/presentation/widgets/player_actions_widget.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/shared/navigation.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

/// 使用确定返回 404 的真实本机 HTTP 服务，不改写已有播放列表。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const device = String.fromEnvironment('QA_DEVICE', defaultValue: 'ipad');
  testWidgets('失败页停止播放、恢复入口与面板布局', (tester) async {
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      request.response.statusCode = HttpStatus.notFound;
      try {
        request.response.write('Missing test stream');
        await request.response.close();
      } on IOException {
        // 被测引擎可以在错误响应后提前断开。
      }
    });
    addTearDown(() => server.close(force: true));
    Future<void> until(bool Function() ready, {int seconds = 130}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(ready(), isTrue);
    }

    Future<void> shot(String stage) async {
      if (Platform.isAndroid) {
        // 有窗口的 TV 使用宿主 adb 截图，避免 Flutter ImageView 转换冻结画面。
        debugPrint('QA_FAILURE_STAGE $stage');
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      } else {
        await binding.takeScreenshot('$device-player-$stage');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seeded_default_preset', true);
    await loadMiniPlayerSetting();
    await loadNativeEngineMode();
    await tester.pumpWidget(app.createApplication());
    await until(() => find.byType(HomeScreen).evaluate().isNotEmpty);
    await until(
      () =>
          AppNav.key.currentContext!.read<MediaProvider>().channels.isNotEmpty,
    );
    final channel = Channel(
      id: 'qa-failure',
      name: '播放失败验收',
      source: [
        for (final name in ['first', 'backup'])
          Source(
            title: name,
            link: 'http://127.0.0.1:${server.port}/$name.m3u8',
            groupTitle: '验收',
            attributes: {},
            duration: -1,
          ),
      ],
    );
    AppNav.key.currentState!.push(
      MaterialPageRoute(
        builder: (_) =>
            PlayerScreen(channel: channel, favoriteChannels: const []),
      ),
    );
    await until(() => find.text('暂时无法播放').evaluate().isNotEmpty);
    await tester.pump(const Duration(milliseconds: 500));
    final mini = AppNav.key.currentContext!.read<MiniPlayerController>();
    expect(mini.backend?.notifier.value.isPlaying, isFalse);
    expect(find.text('重试播放'), findsOneWidget);
    expect(find.byType(PlayerActionsWidget), findsNothing);
    expect(find.byType(XpLiveBadge), findsNothing);
    await shot('failed');
    await tester.tapAt(
      Offset(
        16,
        tester.view.physicalSize.height / tester.view.devicePixelRatio / 2,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PlayerActionsWidget), findsNothing);
    final beforeRetry = requests;
    if (device == 'tv') {
      final retry = tester.widget<XpButton>(
        find.widgetWithText(XpButton, '重试播放'),
      );
      expect(retry.focusNode?.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(ChannelSourceWidget), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    } else {
      await tester.tap(find.text('重试播放'));
    }
    await until(() => requests > beforeRetry);
    await until(() => find.text('暂时无法播放').evaluate().isNotEmpty);
    await tester.tap(find.text('切换来源'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(ChannelSourceWidget), findsOneWidget);
    expect(find.text('源1'), findsOneWidget);
    expect(find.text('源2'), findsOneWidget);
    await shot('sources');
    AppNav.key.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('切换频道'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(ChannelSelectorWidget), findsOneWidget);
    AppNav.key.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('返回频道'));
    await until(() => find.byType(PlayerScreen).evaluate().isEmpty);
    expect(mini.hasMini, isFalse);
    expect(tester.takeException(), isNull);
    binding.reportData ??= {};
    binding.reportData!.addAll({
      'device': '$device-failure',
      'passed': true,
      'retryRequestsIncreased': requests > beforeRetry,
      'sourcePicker': true,
      'channelPicker': true,
      'noFailedMiniPlayer': true,
      'tvKeyboardRetry': device == 'tv',
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
