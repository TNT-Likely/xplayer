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
import 'package:xplayer/localization/app_localizations.dart';

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
  final VoidCallback? onCast;

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
      this.showAudioTrackSelect,
      this.onCast})
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
    final v0 = widget.backend.notifier.value;
    _isPlaying = v0.isPlaying || v0.isBuffering;
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
    final v = widget.backend.notifier.value;
    // 缓冲中视为“播放中”:ExoPlayer 每次微卡都会把 isPlaying 掉成 false,若按钮直接跟随
    // 会在「播放/暂停」间高频抖动。用 isPlaying||isBuffering 表达“用户播放意图”,只有真正
    // 暂停(既不在播也不在缓冲)才显示播放箭头。仅在变化时 setState,避免无谓重建。
    final playing = v.isPlaying || v.isBuffering;
    if (playing != _isPlaying && mounted) {
      setState(() => _isPlaying = playing);
    }
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

    // 当前节目 + 进度/剩余时间 + 下一个节目
    final l = AppLocalizations.of(context)!;
    final nowTs = DateTime.now();
    final curProg = programmeInfo.$2; // 当前节目
    final nextProg = programmeInfo.$3; // 下一个节目
    double? curProgress;
    String? curRemaining;
    if (curProg != null) {
      final totalSec = curProg.stop.difference(curProg.start).inSeconds;
      final elapsedSec = nowTs.difference(curProg.start).inSeconds;
      if (totalSec > 0) curProgress = (elapsedSec / totalSec).clamp(0.0, 1.0);
      final remMin = curProg.stop.difference(nowTs).inMinutes;
      if (remMin > 0) curRemaining = l.epgRemaining(remMin);
    }

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
              // 行1:当前节目标题(无节目单回退频道名)+ 信息chip + IPv6
              Row(
                children: [
                  Flexible(
                    child: Text(
                      curProg != null
                          ? curProg.title
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
              // 行2:当前节目时段 + 剩余时间 + 进度条
              if (curProg != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      "${formatTime(curProg.start)}-${formatTime(curProg.stop)}",
                      style: const TextStyle(
                          color: Colors.white70,
                          decoration: TextDecoration.none,
                          fontSize: 12),
                    ),
                    if (curRemaining != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        curRemaining,
                        style: const TextStyle(
                            color: Colors.white54,
                            decoration: TextDecoration.none,
                            fontSize: 12),
                      ),
                    ],
                  ],
                ),
                if (curProgress != null) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: curProgress,
                      minHeight: 3,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                    ),
                  ),
                ],
              ],
              // 行3:下一个节目
              if (nextProg != null) ...[
                const SizedBox(height: 4),
                Text(
                  "${l.epgNext} ${formatTime(nextProg.start)}  ${nextProg.title}",
                  style: const TextStyle(
                      color: Colors.white54,
                      decoration: TextDecoration.none,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    // 操作按钮组(两种布局共用同一组按钮)
    final hasError = widget.backend.notifier.value.hasError;
    final actionButtons = <Widget>[
      if (hasError) ...[
        XIconButton(
          icon: Icons.refresh,
          label: l.retry,
          autofocus: true, // 出错时操作栏打开默认聚焦"重试"
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
        autofocus: !hasError, // 正常时操作栏打开默认聚焦"播放/暂停"
        icon: _isPlaying ? Icons.pause : Icons.play_arrow,
        label: _isPlaying ? l.pause : l.play,
      ),
      const SizedBox(width: 8),
      // 收藏:常用,排前
      XIconButton(
        onPressed: () async {
          await widget.onFavorite();
          _updateIsFavorite();
        },
        iconColor: _isFavorite ? Colors.red : Colors.white,
        icon: _isFavorite ? Icons.favorite : Icons.favorite_outline,
        label: _isFavorite ? l.favorited : l.favorite,
      ),
      const SizedBox(width: 8),
      XIconButton(
        icon: Icons.list,
        label: l.channelList,
        onPressed: () {
          if (widget.showChannelSelect != null) {
            widget.showChannelSelect!();
          }
        },
      ),
      const SizedBox(width: 8),
      XIconButton(
        icon: Icons.swap_horiz,
        label: l.sourceSwitch,
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
          label: l.quality,
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
          label: l.audioTrack,
          onPressed: () {
            if (widget.showAudioTrackSelect != null) {
              widget.showAudioTrackSelect!();
            }
          },
        ),
        const SizedBox(width: 8),
      ],
      // 投屏(DLNA):始终显示
      if (widget.onCast != null) ...[
        XIconButton(
          icon: Icons.live_tv,
          label: l.actionCast,
          onPressed: () => widget.onCast!(),
        ),
        const SizedBox(width: 8),
      ],
      // 睡眠定时:始终显示
      XIconButton(
        icon: Icons.bedtime,
        label: l.actionSleep,
        onPressed: () {
          if (widget.showSleepTimer != null) widget.showSleepTimer!();
        },
      ),
      const SizedBox(width: 8),
      XIconButton(
        icon: Icons.info_outline,
        label: l.actionDiag,
        onPressed: () {
          if (widget.onToggleDiag != null) {
            widget.onToggleDiag!();
          }
        },
      ),
      if (isMobile) const SizedBox(width: 8),
      if (isMobile)
        XIconButton(
          icon: _orientIcon,
          label: l.actionRotate,
          onPressed: _cycleOrientation,
        ),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        // 高度自适应内容(图标下加了文字标签后更高),并限制不超过屏幕
        constraints: BoxConstraints(
          minHeight: 96,
          maxHeight: MediaQuery.of(context).size.height,
        ),
        // 通栏底:中性灰、较高不透明度,叠在视频上清晰但不过暗
        color: const Color.fromRGBO(48, 48, 48, 0.86),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            // mainAxisSize.min:否则 Column 撑满全屏高度,会让操作栏内容居中、
            // 外层 Align(bottomCenter) 失效(竖屏时操作栏跑到屏幕中间)。
            : Column(
                mainAxisSize: MainAxisSize.min,
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
