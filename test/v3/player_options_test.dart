import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/screens/home.dart';
import 'package:xplayer/presentation/widgets/player_dialogs.dart';
import 'package:xplayer/presentation/widgets/channel_source_widget.dart';
import 'package:xplayer/presentation/widgets/quality_selector_widget.dart';
import 'package:xplayer/presentation/widgets/audio_track_selector_widget.dart';
import 'package:xplayer/presentation/widgets/channel_selector_widget.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/utils/hls_probe.dart';
import 'package:xplayer_ui/xplayer_ui.dart';
import 'adaptive_home_test.dart' show app;
import 'fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final scenario in [
    (const Size(320, 740), false, 2.0),
    (const Size(1194, 834), false, 1.0),
    (const Size(1440, 900), false, 1.0),
    (const Size(960, 540), true, 1.0),
  ]) {
    testWidgets('选择面板 ${scenario.$1} 长文字、关闭和稳定来源编号', (tester) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(FakeMedia(), tv: scenario.$2, scale: scenario.$3),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(HomeScreen));
      final channel = Channel(
        id: 'test',
        name: '测试',
        source: [
          for (var i = 0; i < 2; i++)
            Source(
              title: '',
              link: 'https://example.com/$i.m3u8',
              groupTitle: '测试',
              attributes: {},
              duration: -1,
            ),
        ],
      );
      Future<void> check(Type type) async {
        await tester.pumpAndSettle();
        final panel = find.ancestor(
          of: find.byType(type),
          matching: find.byType(XpSurface),
        );
        final rect = tester.getRect(panel);
        expect(rect.right, lessThanOrEqualTo(scenario.$1.width - 16));
        expect(rect.bottom, lessThanOrEqualTo(scenario.$1.height - 16));
        expect(rect.top, greaterThanOrEqualTo(16));
        expect(tester.takeException(), isNull);
      }

      PlayerDialogs.showSourceSwitcher(
        context,
        channel,
        channel.source.first.link,
        (_) async {},
      );
      await check(ChannelSourceWidget);
      tester.element(find.byType(ChannelSourceWidget)).markNeedsBuild();
      await tester.pumpAndSettle();
      expect(find.text('源1'), findsOneWidget);
      expect(find.text('源2'), findsOneWidget);
      expect(find.text('源3'), findsNothing);
      await tester.tap(find.byTooltip('关闭源切换'));
      await tester.pumpAndSettle();
      expect(find.byType(ChannelSourceWidget), findsNothing);
      PlayerDialogs.showQualitySwitcher(
        context,
        const [
          HlsVariant(
            url: 'https://example.com/1080.m3u8',
            height: 1080,
            bandwidth: 4900000,
          ),
        ],
        null,
        (_) async {},
      );
      await check(QualitySelectorWidget);
      await tester.tap(find.byTooltip('关闭画质'));
      await tester.pumpAndSettle();
      PlayerDialogs.showAudioTrackSwitcher(context, const [
        AudioTrack(
          id: '1',
          label: '中文多声道',
          codec: 'aac',
          channels: 6,
          isSelected: true,
        ),
      ], (_) async {});
      await check(AudioTrackSelectorWidget);
      await tester.tap(find.byTooltip('关闭音轨'));
      await tester.pumpAndSettle();
      PlayerDialogs.showSleepTimerSwitcher(context, (_) async {});
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('关闭睡眠定时'));
      await tester.pumpAndSettle();
      final media = FakeMedia();
      PlayerDialogs.showChannelSelectWidget(
        context,
        media.channels,
        media.channels.first,
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChannelSelectorWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(ChannelSelectorWidget))).pop();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
