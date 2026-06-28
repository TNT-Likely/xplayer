import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/shared/components/ipv6_badge.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/utils/playlist_util.dart';
import 'package:xplayer/utils/url_utils.dart';

// 定义回调函数类型
typedef PlayPauseCallback = void Function(bool isPlaying);
typedef FavoriteCallback = Future<void> Function();

/// 朝向模式:自动跟随设备 / 锁定竖屏 / 锁定横屏(锁定即使系统开了自动旋转也生效)。
enum _OrientMode { auto, portrait, landscape }

class PlayerActionsWidget extends StatefulWidget {
  final XPlayerBackend backend;
  final PlayPauseCallback onPlayPause;
  final FavoriteCallback onFavorite;
  final List<Channel> favoriteChannels;
  final Channel channel;
  final VoidCallback? onFocusChange;
  final VoidCallback? showChannelSelect;
  final VoidCallback? onRetryInit;
  final VoidCallback? showSourceSwitch;
  final VoidCallback? onToggleDiag;
  /// 当前播放的源地址(用于判断 IPv6 角标)
  final String? sourceLink;
  /// 当前流是否有多档画质可选(决定画质按钮是否显示)
  final bool hasQualityOptions;
  final VoidCallback? showQualitySelect;
  final VoidCallback? showSleepTimer;
  /// 是否有多音轨(决定音轨按钮是否显示)
  final bool hasAudioTracks;
  final VoidCallback? showAudioTrackSelect;

  const PlayerActionsWidget(
      {Key? key,
      required this.backend,
      required this.onPlayPause,
      required this.onFavorite,
      required this.favoriteChannels,
      required this.channel,
      this.onFocusChange,
      this.showChannelSelect,
      this.onRetryInit,
      this.showSourceSwitch,
      this.onToggleDiag,
      this.sourceLink,
      this.hasQualityOptions = false,
      this.showQualitySelect,
      this.showSleepTimer,
      this.hasAudioTracks = false,
      this.showAudioTrackSelect})
      : super(key: key);

  @override
  State<PlayerActionsWidget> createState() => _PlayerActionsWidgetState();
}

class _PlayerActionsWidgetState extends State<PlayerActionsWidget>
    with TickerProviderStateMixin {
  late bool _isPlaying;
  bool _isFavorite = false;
  _OrientMode _orientMode = _OrientMode.auto;
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
    _isPlaying = widget.backend.notifier.value.isPlaying;
    _updateIsFavorite();
    if (!widget.backend.notifier.value.hasError) {
      widget.backend.notifier.addListener(_updateIsPlaying);
    }
  }

  @override
  void dispose() {
    widget.backend.notifier.removeListener(_updateIsPlaying);
    super.dispose();
    // controller.dispose();
  }

  void _updateIsPlaying() {
    setState(() {
      _isPlaying = widget.backend.notifier.value.isPlaying;
    });
  }

  void _handlePlayPause() {
    if (_isPlaying) {
      widget.backend.pause();
    } else {
      widget.backend.play();
    }
    widget.onPlayPause(_isPlaying);
  }

  // 朝向按钮:循环 自动 → 锁竖屏 → 锁横屏 → 自动。
  // 自动=交还系统跟随传感器;锁定=钉到单一朝向(覆盖系统的自动旋转)。
  void _cycleOrientation() {
    setState(() {
      _orientMode = _OrientMode.values[(_orientMode.index + 1) % 3];
    });
    switch (_orientMode) {
      case _OrientMode.auto:
        SystemChrome.setPreferredOrientations(const []);
        break;
      case _OrientMode.portrait:
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
      case _OrientMode.landscape:
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
  }

  IconData get _orientIcon {
    switch (_orientMode) {
      case _OrientMode.auto:
        return Icons.screen_rotation; // 自动旋转
      case _OrientMode.portrait:
        return Icons.screen_lock_portrait; // 锁定竖屏
      case _OrientMode.landscape:
        return Icons.screen_lock_landscape; // 锁定横屏
    }
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
                  if (isIpv6Url(widget.sourceLink)) ...[
                    const SizedBox(width: 6),
                    const Ipv6Badge(),
                  ],
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
      if (widget.backend.notifier.value.hasError) ...[
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
      // 画质选择:仅当流含多档码率时出现
      if (widget.hasQualityOptions) ...[
        XIconButton(
          icon: Icons.high_quality,
          onPressed: () {
            if (widget.showQualitySelect != null) {
              widget.showQualitySelect!();
            }
          },
        ),
        const SizedBox(width: 8),
      ],
      // 音轨选择:仅多音轨时出现
      if (widget.hasAudioTracks) ...[
        XIconButton(
          icon: Icons.audiotrack,
          onPressed: () {
            if (widget.showAudioTrackSelect != null) {
              widget.showAudioTrackSelect!();
            }
          },
        ),
        const SizedBox(width: 8),
      ],
      // 睡眠定时:始终显示
      XIconButton(
        icon: Icons.bedtime,
        onPressed: () {
          if (widget.showSleepTimer != null) widget.showSleepTimer!();
        },
      ),
      const SizedBox(width: 8),
      XIconButton(
        icon: Icons.info_outline,
        onPressed: () {
          if (widget.onToggleDiag != null) {
            widget.onToggleDiag!();
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
      if (isMobile) const SizedBox(width: 8),
      if (isMobile)
        XIconButton(
          icon: _orientIcon,
          onPressed: _cycleOrientation,
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
            // 窄屏:信息在上、按钮在下;按钮可能多于一屏宽 → 横向可滚动,避免溢出
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  infoRow,
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actionButtons,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }

  /// 由视频分辨率(取较短边作为"线数")映射清晰度档:4K/1080P/720P/576P/SD。
  String? _resolutionLabel() {
    final Size s = widget.backend.notifier.value.size;
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
