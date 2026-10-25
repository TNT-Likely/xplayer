import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/presentation/adapters/media_presentation.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/utils/playlist_util.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

typedef PlayPauseCallback = void Function(bool isPlaying);
typedef FavoriteCallback = Future<void> Function();

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

  const PlayerActionsWidget({
    Key? key,
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
    this.onCast,
  }) : super(key: key);

  @override
  State<PlayerActionsWidget> createState() => _PlayerActionsWidgetState();
}

class _PlayerActionsWidgetState extends State<PlayerActionsWidget> {
  _OrientMode _orientation = _OrientMode.auto;
  void _rotate() {
    setState(
      () => _orientation = _OrientMode.values[(_orientation.index + 1) % 3],
    );
    SystemChrome.setPreferredOrientations(switch (_orientation) {
      _OrientMode.auto => [],
      _OrientMode.portrait => [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      _OrientMode.landscape => [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = context.watch<MediaProvider>();
    final l = AppLocalizations.of(context)!;
    final p = XpTheme.of(context).palette;
    final now = DateTime.now();
    final programme = PlaylistUtil.findCurrentAndNextProgramme(
      media.programmes,
      widget.channel.id,
      now,
    ).$2;
    final presentation = MediaPresentation(media, now: now);
    final favorite = media.favoriteChannels.any(
      (c) => c.id == widget.channel.id,
    );
    return ValueListenableBuilder<XPlayerValue>(
      valueListenable: widget.backend.notifier,
      builder: (context, value, _) {
        final playing = value.isPlaying || value.isBuffering;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: p.background.withValues(alpha: .96),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .8,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: Focus(
                    onKeyEvent: (_, __) {
                      widget.onFocusChange?.call();
                      return KeyEventResult.ignored;
                    },
                    child: Listener(
                      onPointerDown: (_) => widget.onFocusChange?.call(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: XpChannelIdentity(
                                  channel: presentation.channel(widget.channel),
                                ),
                              ),
                              XpFavouriteButton(
                                channelName: widget.channel.name,
                                value: favorite,
                                onChanged: (_) => widget.onFavorite(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            programme?.title ?? widget.channel.name,
                            style: TextStyle(
                              fontSize: XpTheme.of(context).titleSize,
                            ),
                          ),
                          if (programme != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${xpTime(programme.start)} — ${xpTime(programme.stop)}',
                              style: TextStyle(color: p.muted),
                            ),
                            const SizedBox(height: 10),
                            XpProgress(
                              value:
                                  presentProgramme(programme).progressAt(now) ??
                                  0,
                            ),
                          ],
                          const SizedBox(height: 16),
                          XpPlayerControls(
                            paused: !playing,
                            onTogglePause: value.hasError
                                ? null
                                : () {
                                    if (playing) {
                                      widget.backend.pause();
                                    } else {
                                      widget.backend.play();
                                    }
                                    widget.onPlayPause(playing);
                                  },
                            onChannels: widget.showChannelSelect,
                            qualityLabel: widget.hasQualityOptions
                                ? l.quality
                                : null,
                            onQuality: widget.hasQualityOptions
                                ? widget.showQualitySelect
                                : null,
                            audioLabel: widget.hasAudioTracks
                                ? l.audioTrack
                                : null,
                            onAudio: widget.hasAudioTracks
                                ? widget.showAudioTrackSelect
                                : null,
                            onSleep: widget.showSleepTimer,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (value.hasError && widget.onRetryInit != null)
                                XpButton(
                                  label: l.retry,
                                  onPressed: widget.onRetryInit,
                                ),
                              if (widget.channel.source.length > 1 &&
                                  widget.showSourceSwitch != null)
                                XpButton(
                                  label: l.sourceSwitch,
                                  icon: XpSymbol.sync,
                                  onPressed: widget.showSourceSwitch,
                                  variant: XpButtonVariant.secondary,
                                ),
                              if (widget.onCast != null)
                                XpButton(
                                  label: l.actionCast,
                                  icon: XpSymbol.cast,
                                  onPressed: widget.onCast,
                                  variant: XpButtonVariant.secondary,
                                ),
                              if (widget.onToggleDiag != null)
                                XpButton(
                                  label: l.actionDiag,
                                  icon: XpSymbol.info,
                                  onPressed: widget.onToggleDiag,
                                  variant: XpButtonVariant.ghost,
                                ),
                              if (context.watch<GlobalProvider>().isMobile)
                                XpButton(
                                  label:
                                      '${l.actionRotate} · ${_orientation.name}',
                                  onPressed: _rotate,
                                  variant: XpButtonVariant.ghost,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
