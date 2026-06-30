import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/widgets/channel_selector_widget.dart';
import 'package:xplayer/presentation/widgets/channel_source_widget.dart';
import 'package:xplayer/presentation/widgets/quality_selector_widget.dart';
import 'package:xplayer/presentation/widgets/audio_track_selector_widget.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/services/sleep_timer.dart';
import 'package:xplayer/utils/hls_probe.dart';

class PlayerDialogs {
  static void showChannelSelectWidget(
    BuildContext context,
    List<Channel> channels,
    Channel selectedChannel,
    Function(Channel) onSelected,
  ) {
    final bool wide = MediaQuery.of(context).size.width >= 720;
    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: wide ? Alignment.center : Alignment.centerLeft,
          child: Container(
            width: wide
                ? MediaQuery.of(context).size.width * 0.9
                : max(280, MediaQuery.of(context).size.width * 0.85),
            height: MediaQuery.of(context).size.height,
            color: const Color.fromRGBO(0, 0, 0, 0.55),
            child: ChannelSelectorWidget(
              currentChannel: selectedChannel,
              // 切台+关闭由调用方(player._showChannelSelectWidget)负责,
              // 这里不要再 pop,否则会连播放页一起弹掉。
              onSelected: onSelected,
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position:
              Tween(begin: const Offset(-1.0, 0.0), end: const Offset(0.0, 0.0))
                  .animate(anim),
          child: child,
        );
      },
    );
  }

  // showProgrammeList 已删除:节目单入口合并进频道选择器(ChannelSelectorWidget)。

  static void showSourceSwitcher(
    BuildContext context,
    Channel channel,
    String link,
    Future<void> Function(String link) onSourceSwitch,
  ) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: max(200, MediaQuery.of(context).size.width * 0.3),
            height: MediaQuery.of(context).size.height * 1.0,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(20, 20, 20, 0.92),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ChannelSourceWidget(
              channel: channel,
              link: link,
              onSourceSwitch: onSourceSwitch,
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position:
              Tween(begin: const Offset(1.0, 0.0), end: const Offset(0.0, 0.0))
                  .animate(anim),
          child: child,
        );
      },
    );
  }

  /// 画质(多码率)选择浮层 —— 侧边浮层,与切源一致
  static void showQualitySwitcher(
    BuildContext context,
    List<HlsVariant> variants,
    String? currentUrl,
    OnQualitySelectCallback onSelect,
  ) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: max(220, MediaQuery.of(context).size.width * 0.3),
            height: MediaQuery.of(context).size.height * 1.0,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(20, 20, 20, 0.92),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: QualitySelectorWidget(
              variants: variants,
              currentUrl: currentUrl,
              onSelect: onSelect,
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position:
              Tween(begin: const Offset(1.0, 0.0), end: const Offset(0.0, 0.0))
                  .animate(anim),
          child: child,
        );
      },
    );
  }

  /// 通用右侧浮层容器(睡眠/音轨复用)。
  static void _rightSheet(BuildContext context, Widget child) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: max(220, MediaQuery.of(context).size.width * 0.3),
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(20, 20, 20, 0.92),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: child,
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position:
            Tween(begin: const Offset(1.0, 0.0), end: const Offset(0.0, 0.0))
                .animate(anim),
        child: child,
      ),
    );
  }

  /// 睡眠定时浮层:关闭 / 15 / 30 / 60 / 90 分钟。null = 关闭。
  static void showSleepTimerSwitcher(
    BuildContext context,
    Future<void> Function(Duration? d) onSelect,
  ) {
    final l = AppLocalizations.of(context)!;
    final options = <(String, Duration?)>[
      (l.sleepOff, null),
      (l.sleepMinutes(15), const Duration(minutes: 15)),
      (l.sleepMinutes(30), const Duration(minutes: 30)),
      (l.sleepMinutes(60), const Duration(minutes: 60)),
      (l.sleepMinutes(90), const Duration(minutes: 90)),
    ];
    _rightSheet(
      context,
      Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((o) {
              final selected = o.$2 == null
                  ? !sleepTimer.isActive
                  : (sleepTimer.isActive &&
                      sleepTimer.remaining != null &&
                      (sleepTimer.remaining!.inMinutes - o.$2!.inMinutes).abs() <=
                          1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: XTextButton(
                  text: o.$1,
                  size: XTextButtonSize.large,
                  width: 180,
                  autofocus: selected, // 打开即聚焦当前项
                  textStyle: const TextStyle(fontSize: 13),
                  type: selected
                      ? XTextButtonType.primary
                      : XTextButtonType.defaultType,
                  onPressed: () => onSelect(o.$2),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// 音轨选择浮层。
  static void showAudioTrackSwitcher(
    BuildContext context,
    List<AudioTrack> tracks,
    Future<void> Function(String id) onSelect,
  ) {
    _rightSheet(
      context,
      AudioTrackSelectorWidget(tracks: tracks, onSelect: onSelect),
    );
  }
}
