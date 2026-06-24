import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/utils/playlist_util.dart';

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

    // 宽屏(平板/TV/横屏):右侧空间富余,按钮组放到右边;
    // 窄屏(手机竖屏):按钮另起一行左对齐。
    final wide = MediaQuery.of(context).size.width >= 600;

    // 频道信息:台标 + 当前/下一节目(无节目单时显示频道名)
    final infoRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.channel.logo != null && widget.channel.logo!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: widget.channel.logo!,
            height: 42,
            fit: BoxFit.fitHeight,
            errorWidget: (context, url, error) => iDWidget,
          )
        else
          iDWidget,
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      programmeInfo.$2 != null
                          ? programmeInfo.$2!.title
                          : (widget.channel.name.isNotEmpty
                              ? widget.channel.name
                              : widget.channel.id),
                      style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          fontSize: 22),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _streamInfoChip(),
                ],
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
          ),
        ),
      ],
    );

    // 操作按钮组(两种布局共用同一组按钮)
    final actionButtons = <Widget>[
      if (widget.controller.value.hasError) ...[
        XIconButton(
          icon: Icons.refresh,
          onPressed: () {
            if (widget.onRetryInit != null) {
              widget.onRetryInit!();
            }
          },
        ),
        const SizedBox(width: 8),
      ],
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
        onPressed: () async {
          await widget.onFavorite();
          _updateIsFavorite();
        },
        iconColor: _isFavorite ? Colors.red : Colors.white,
        icon: _isFavorite ? Icons.favorite : Icons.favorite_outline,
      ),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: min(MediaQuery.of(context).size.height, 130),
        // 通栏淡灰底:无圆角、无边框,与视频画面区分但不抢眼
        color: const Color.fromRGBO(48, 48, 48, 0.55),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: wide
            // 宽屏:频道信息占左侧,按钮组靠右,填满右侧空白
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: infoRow),
                  const SizedBox(width: 16),
                  Row(mainAxisSize: MainAxisSize.min, children: actionButtons),
                ],
              )
            // 窄屏:信息在上、按钮在下并左对齐
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  infoRow,
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: actionButtons,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }

  /// 由视频分辨率(取较短边作为"线数")映射清晰度档:4K/1080P/720P/576P/SD。
  String? _resolutionLabel() {
    final Size s = widget.controller.value.size;
    final int lines = (s.width < s.height ? s.width : s.height).round();
    if (lines <= 0) return null;
    if (lines >= 2000) return '4K';
    if (lines >= 1000) return '1080P';
    if (lines >= 700) return '720P';
    if (lines >= 500) return '576P';
    return 'SD';
  }

  /// 流信息小标签(分辨率;fps 待 fork 透出后再拼上)。
  Widget _streamInfoChip() {
    final String? label = _resolutionLabel();
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none),
      ),
    );
  }

  String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time.toLocal());
  }
}
