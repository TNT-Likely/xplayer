import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/presentation/widgets/channel_selector_widget.dart';
import 'package:xplayer/presentation/widgets/channel_source_widget.dart';
import 'package:xplayer/presentation/widgets/quality_selector_widget.dart';
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
              color: const Color.fromRGBO(0, 0, 0, 0.3),
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
              color: const Color.fromRGBO(0, 0, 0, 0.3),
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
}
