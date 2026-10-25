import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/main.dart' as app;
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/screens/home.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/presentation/widgets/operation_hint_dialog.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/shared/navigation.dart';
import 'package:xplayer/utils/player_settings.dart';

/// 仅在专用模拟器上手动运行，配置服务提供合成 FLV 与即时解析的真实直播地址。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const device = String.fromEnvironment('QA_DEVICE', defaultValue: 'phone');
  const configUrl = String.fromEnvironment('QA_STREAM_CONFIG');
  const audioHoldSeconds = int.fromEnvironment('QA_AUDIO_HOLD_SECONDS');
  testWidgets('真实主播放器的 FLV、平台请求上下文与原生视频输出', (tester) async {
    expect(configUrl, isNotEmpty);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    late Map<String, dynamic> config;
    try {
      final response = await (await client.getUrl(
        Uri.parse(configUrl),
      )).close();
      config =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
    Future<bool> until(bool Function() condition, {int seconds = 45}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (!condition() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      return condition();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seeded_default_preset', true);
    await prefs.setBool('auto_refresh_channels', false);
    await prefs.setBool('auto_refresh_programmes', false);
    await loadMiniPlayerSetting();
    await loadNativeEngineMode();
    await tester.pumpWidget(app.createApplication());
    expect(
      await until(() => find.byType(HomeScreen).evaluate().isNotEmpty),
      isTrue,
    );
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    final mini = AppNav.key.currentContext!.read<MiniPlayerController>();
    final results = <Map<String, Object?>>[];
    for (final source in config['sources'] as List) {
      final name = source['name'] as String;
      final channel = Channel(
        id: 'probe-$name',
        name: name,
        source: [
          Source(
            title: name,
            link: source['url'] as String,
            groupTitle: '播放验收',
            attributes: Map<String, String>.from(source['headers'] as Map),
            duration: -1,
          ),
        ],
      );
      final watch = Stopwatch()..start();
      AppNav.key.currentState!.push(
        MaterialPageRoute(
          builder: (_) =>
              PlayerScreen(channel: channel, favoriteChannels: const []),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      final ready = await until(() {
        final backend = mini.backend;
        final value = backend?.notifier.value;
        return value != null &&
            value.isPlaying &&
            !value.isBuffering &&
            value.size.width > 0 &&
            (backend?.diagnostics?.value['firstFrameRendered'] == true ||
                ((backend?.diagnostics?.value['renderedFrames'] as num?) ?? 0) >
                    0);
      });
      final backend = mini.backend;
      final initial = backend?.notifier.value;
      final firstFrames =
          (backend?.diagnostics?.value['renderedFrames'] as num?) ?? 0;
      final progressWatch = Stopwatch()..start();
      final moving =
          ready &&
          await until(() {
            if (!identical(mini.backend, backend) ||
                backend == null ||
                initial == null) {
              return false;
            }
            final positionMoves =
                backend.notifier.value.position - initial.position >=
                const Duration(seconds: 2);
            final framesMove =
                ((backend.diagnostics?.value['renderedFrames'] as num?) ?? 0) -
                    firstFrames >=
                30;
            // 原生直播 HLS 窗口会滑动，使用连续渲染帧数证明视频推进。
            return progressWatch.elapsed >= const Duration(seconds: 2) &&
                (positionMoves || framesMove);
          }, seconds: 15);
      final diag = backend?.diagnostics?.value ?? {};
      final audioReady =
          diag['audioSampleFormat'] != null ||
          '${diag['audioDecoder'] ?? ''}'.isNotEmpty;
      final hint = find.byType(OperationHintDialog);
      if (hint.evaluate().isNotEmpty) {
        await tester.tap(
          find.text(AppLocalizations.of(tester.element(hint))!.hintGotIt),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
      final result = <String, Object?>{
        'name': name,
        'passed': ready && moving && audioReady,
        'backend': '${backend.runtimeType}',
        'firstFrameRendered': ready,
        'videoWidth': initial?.size.width,
        'videoHeight': initial?.size.height,
        'positionAdvanced':
            backend != null &&
            initial != null &&
            backend.notifier.value.position - initial.position >=
                const Duration(seconds: 2),
        'renderedFramesAdvanced':
            ((diag['renderedFrames'] as num?) ?? 0) - firstFrames >= 30,
        'audioSampleFormat': diag['audioSampleFormat'],
        'audioOutputDriver': diag['audioOutputDriver'],
        'audioDecoder': diag['audioDecoder'],
        'renderedFrames': diag['renderedFrames'],
        'videoMime': diag['videoMime'],
        'audioMime': diag['audioMime'],
        'elapsedMs': watch.elapsedMilliseconds,
      };
      results.add(result);
      if (audioHoldSeconds > 0 && ready) {
        // 留出系统 PCM 采样窗口；解码轨道存在不能替代实际声音输出检查。
        debugPrint('QA_AUDIO_READY $name');
        final end = DateTime.now().add(
          const Duration(seconds: audioHoldSeconds),
        );
        while (DateTime.now().isBefore(end)) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      await binding.takeScreenshot('$device-live-$name');
      await tester.tap(find.byTooltip('返回频道'));
      expect(
        await until(
          () => find.byType(PlayerScreen).evaluate().isEmpty,
          seconds: 10,
        ),
        isTrue,
      );
      await mini.close();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }
    binding.reportData ??= {};
    binding.reportData!.addAll({
      'device': '$device-live',
      'passed': results.every((r) => r['passed'] == true),
      'results': results,
    });
    expect(
      results.every((r) => r['passed'] == true),
      isTrue,
      reason: jsonEncode(results),
    );
  }, timeout: const Timeout(Duration(minutes: 8)));
}
