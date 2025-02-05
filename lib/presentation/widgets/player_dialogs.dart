import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/presentation/widgets/channel_select_list_widget.dart';
import 'package:xplayer/presentation/widgets/channel_source_widget.dart';
import 'package:xplayer/presentation/widgets/programme_list_widget.dart';

class PlayerDialogs {
  static void showChannelSelectWidget(
    BuildContext context,
    List<Channel> channels,
    Channel selectedChannel,
    Function(Channel) onSelected,
  ) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: max(200, MediaQuery.of(context).size.width * 0.3),
            height: MediaQuery.of(context).size.height * 1.0,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ChannelSelectListWidget(
              channels: channels,
              currentChannel: selectedChannel,
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

  static void showProgrammeList(
    BuildContext context,
    List<Programme> programmes,
    Function(Programme) onSelected,
  ) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: max(200, MediaQuery.of(context).size.width * 0.3),
            height: MediaQuery.of(context).size.height * 1.0,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ProgrammeListWidget(
              programmes: programmes,
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
}
