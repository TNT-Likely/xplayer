import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/utils/playlist_util.dart';
import 'package:flutter/services.dart';

// 定义回调函数类型
typedef PlayPauseCallback = void Function(bool isPlaying);
typedef FavoriteCallback = Future<void> Function();

class PlayerActionsWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final PlayPauseCallback onPlayPause;
  final FavoriteCallback onFavorite;
  final List<Channel> favoriteChannels;
  final Channel channel;
  final VoidCallback? onFocusChange;
  final VoidCallback? onProgramme;
  final VoidCallback? showChannelSelect;
  final VoidCallback? onRetryInit;
  final VoidCallback? showSourceSwitch;

  const PlayerActionsWidget(
      {Key? key,
      required this.controller,
      required this.onPlayPause,
      required this.onFavorite,
      required this.favoriteChannels,
      required this.channel,
      this.onFocusChange,
      this.onProgramme,
      this.showChannelSelect,
      this.onRetryInit,
      this.showSourceSwitch})
      : super(key: key);

  @override
  State<PlayerActionsWidget> createState() => _PlayerActionsWidgetState();
}

class _PlayerActionsWidgetState extends State<PlayerActionsWidget>
    with TickerProviderStateMixin {
  late bool _isPlaying;
  bool _isFavorite = false;
  bool isPortrait = true;
  late final AnimationController controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  )..forward();

  @override
  void didUpdateWidget(PlayerActionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.favoriteChannels != oldWidget.favoriteChannels ||
        widget.channel != oldWidget.channel) {
      _updateIsFavorite();
    }
  }

  void _updateIsFavorite() {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    setState(() {
      _isFavorite = mediaProvider.favoriteChannels.any(
        (element) => element.id == widget.channel.id,
      );
    });
  }

  (int currentIndex, Programme? currentProgramme, Programme? nextProgramme)
      get programmeInfo {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    final info = PlaylistUtil.findCurrentAndNextProgramme(
        mediaProvider.programmes, widget.channel.id ?? '');

    return info;
  }

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.controller.value.isPlaying;
    _updateIsFavorite();
    if (!widget.controller.value.hasError) {
      widget.controller.addListener(_updateIsPlaying);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateIsPlaying);
    super.dispose();
    // controller.dispose();
  }

  void _updateIsPlaying() {
    setState(() {
      _isPlaying = widget.controller.value.isPlaying;
    });
  }

  void toggleOrientation() {
    setState(() {
      isPortrait = !isPortrait;
      if (isPortrait) {
        // 切换到竖屏
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        // 切换到横屏
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
  }

  void _handlePlayPause() {
    if (_isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
    widget.onPlayPause(_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final iDWidget = Text(
      widget.channel.id,
      style: const TextStyle(
          color: Colors.white, fontSize: 50, decoration: TextDecoration.none),
    );

    final globalProvider = Provider.of<GlobalProvider>(context, listen: false);

    final isMobile = globalProvider.isMobile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: min(MediaQuery.of(context).size.height, 130),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.channel.logo != null &&
                      widget.channel.logo!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.channel.logo!,
                      height: 42,
                      fit: BoxFit.fitHeight,
                      errorWidget: (context, url, error) {
                        return iDWidget;
                      },
                    )
                  else
                    iDWidget,
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (programmeInfo.$2 != null)
                        Text(
                          programmeInfo.$2!.title,
                          style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                              fontSize: 22),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      if (programmeInfo.$3 != null)
                        Text(
                          "${formatTime(programmeInfo.$3!.start)}-${formatTime(programmeInfo.$3!.stop)}  ${programmeInfo.$3!.title}",
                          style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.controller.value.hasError)
                    Row(children: [
                      XIconButton(
                        icon: Icons.refresh,
                        onPressed: () {
                          if (widget.onRetryInit != null) {
                            widget.onRetryInit!();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                    ]),
                  XIconButton(
                    onPressed: _handlePlayPause,
                    icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  const SizedBox(width: 8),
                  XIconButton(
                    icon: Icons.list,
                    onPressed: () {
                      if (widget.showChannelSelect != null) {
                        widget.showChannelSelect!();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  XIconButton(
                    icon: Icons.swap_horiz,
                    onPressed: () {
                      if (widget.showSourceSwitch != null) {
                        widget.showSourceSwitch!();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  XIconButton(
                    icon: Icons.event_note,
                    onPressed: () {
                      if (widget.onProgramme != null) {
                        widget.onProgramme!();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  XIconButton(
                    onPressed: () async {
                      await widget.onFavorite();
                      _updateIsFavorite();
                    },
                    iconColor: _isFavorite ? Colors.red : Colors.white,
                    icon: _isFavorite ? Icons.favorite : Icons.favorite_outline,
                  ),
                  if (isMobile)
                    const SizedBox(
                      width: 8,
                    ),
                  if (isMobile)
                    XIconButton(
                      icon:
                          isPortrait ? Icons.fullscreen : Icons.fullscreen_exit,
                      onPressed: toggleOrientation,
                    )
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time.toLocal());
  }
}
