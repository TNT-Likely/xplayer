import 'package:flutter/material.dart';
import '../../foundation.dart';
import 'channel.dart';
import 'models.dart';

class XpPlayerStatusView extends StatelessWidget {
  const XpPlayerStatusView(
      {super.key,
      required this.phase,
      required this.channelName,
      this.onRetry,
      this.retryFocusNode,
      this.onSwitchSource,
      this.onSwitchChannel,
      this.onCancel,
      this.detail,
      this.paused = false,
      this.onToggleAudio});
  final XpPlaybackPhase phase;
  final String channelName;
  final String? detail;
  final VoidCallback? onRetry,
      onSwitchSource,
      onSwitchChannel,
      onCancel,
      onToggleAudio;
  final bool paused;
  final FocusNode? retryFocusNode;
  @override
  Widget build(BuildContext context) {
    if (phase == XpPlaybackPhase.playing || phase == XpPlaybackPhase.paused) {
      return const SizedBox.shrink();
    }
    if (phase == XpPlaybackPhase.connecting ||
        phase == XpPlaybackPhase.buffering) {
      final theme = XpTheme.of(context);
      return IgnorePointer(
        child: Center(
          child: SizedBox.square(
            dimension: theme.isTv ? 36 : 28,
            child: CircularProgressIndicator(
              value: theme.reduceMotion ? .75 : null,
              strokeWidth: 2.5,
              color: Colors.white,
              semanticsLabel:
                  phase == XpPlaybackPhase.buffering ? '正在缓冲' : '正在连接频道',
            ),
          ),
        ),
      );
    }
    final (title, copy, label, icon) = switch (phase) {
      XpPlaybackPhase.error => (
          '暂时无法播放',
          detail ?? (onSwitchSource == null ? '请重试，或切换其他频道。' : '请重试，或更换播放来源。'),
          '重试播放',
          XpSymbol.info
        ),
      XpPlaybackPhase.unsupported => (
          '当前设备无法播放这个格式',
          detail ?? '可以尝试兼容模式，或换一个源。',
          '尝试兼容模式',
          XpSymbol.info
        ),
      XpPlaybackPhase.audioOnly => (
          paused ? '音频已暂停' : '这是一个音频频道',
          channelName,
          paused ? '继续音频' : '暂停音频',
          XpSymbol.volume
        ),
      _ => ('', '', '', XpSymbol.info),
    };
    final theme = XpTheme.of(context), p = theme.palette;
    final callback =
        phase == XpPlaybackPhase.audioOnly ? onToggleAudio : onRetry;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              XpIcon(icon, size: theme.isTv ? 36 : 28, color: p.muted),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: theme.isTv ? 26 : 20,
                      fontWeight: FontWeight.w500,
                      color: p.foreground)),
              const SizedBox(height: 8),
              Text(copy,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: theme.bodySize, color: p.muted, height: 1.5)),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (callback != null)
                    XpButton(
                        label: label,
                        focusNode: retryFocusNode,
                        autofocus: theme.isTv,
                        onPressed: callback),
                  if (onSwitchSource != null)
                    XpButton(
                        label: '切换来源',
                        onPressed: onSwitchSource,
                        variant: XpButtonVariant.secondary),
                  if (onSwitchChannel != null)
                    XpButton(
                        label: '切换频道',
                        onPressed: onSwitchChannel,
                        variant: onSwitchSource == null
                            ? XpButtonVariant.secondary
                            : XpButtonVariant.ghost),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class XpPlayerControls extends StatelessWidget {
  const XpPlayerControls(
      {super.key,
      required this.paused,
      required this.onTogglePause,
      this.onVolume,
      this.onFullscreen,
      this.onChannels,
      this.qualityLabel,
      this.onQuality,
      this.audioLabel,
      this.onAudio,
      this.onSleep,
      this.live = true});
  final bool paused, live;
  final VoidCallback? onTogglePause,
      onVolume,
      onFullscreen,
      onChannels,
      onQuality,
      onAudio,
      onSleep;
  final String? qualityLabel, audioLabel;
  @override
  Widget build(BuildContext context) => Wrap(
          spacing: 4,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            XpIconButton(
                icon: paused ? XpSymbol.play : XpSymbol.pause,
                label: paused ? '继续播放' : '暂停播放',
                onPressed: onTogglePause),
            if (onVolume != null)
              XpIconButton(
                  icon: XpSymbol.volume, label: '播放音量', onPressed: onVolume),
            if (live) const XpLiveBadge(),
            if (qualityLabel != null && onQuality != null)
              XpButton(
                  label: qualityLabel!,
                  onPressed: onQuality,
                  variant: XpButtonVariant.ghost),
            if (audioLabel != null && onAudio != null)
              XpButton(
                  label: audioLabel!,
                  onPressed: onAudio,
                  variant: XpButtonVariant.ghost),
            if (onSleep != null)
              XpIconButton(
                  icon: XpSymbol.clock, label: '睡眠定时', onPressed: onSleep),
            if (onChannels != null)
              XpIconButton(
                  icon: XpSymbol.channels,
                  label: '切换频道',
                  onPressed: onChannels),
            if (onFullscreen != null)
              XpIconButton(
                  icon: XpSymbol.full, label: '全屏播放', onPressed: onFullscreen),
          ]);
}

class XpMiniPlayer extends StatelessWidget {
  const XpMiniPlayer(
      {super.key,
      required this.channel,
      required this.paused,
      required this.onRestore,
      required this.onTogglePause,
      required this.onClose,
      this.epgStatus = XpEpgStatus.ready});
  final XpChannelData channel;
  final bool paused;
  final XpEpgStatus epgStatus;
  final VoidCallback onRestore, onTogglePause, onClose;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    return LayoutBuilder(
        builder: (context, box) => XpSurface(
            padding: const EdgeInsets.all(8),
            raised: true,
            child: Row(children: [
              Expanded(
                  child: Semantics(
                      button: true,
                      label: '展开 ${channel.name} 播放器',
                      child: InkWell(
                          onTap: onRestore,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(children: [
                                if (box.maxWidth >=
                                    (theme.isTv ? 400 : 300)) ...[
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                          width: theme.isTv ? 90 : 58,
                                          height: theme.isTv ? 58 : 44,
                                          child: XpArtwork(channel: channel))),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(channel.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: theme.bodySize,
                                              color: p.foreground)),
                                      if (epgStatus.hasCurrentMetadata &&
                                          channel.programme != null) ...[
                                        const SizedBox(height: 5),
                                        Text(channel.programme!.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: theme.smallSize,
                                                color: p.muted))
                                      ],
                                    ])),
                              ]))))),
              XpIconButton(
                  icon: paused ? XpSymbol.play : XpSymbol.pause,
                  label: paused ? '继续播放' : '暂停播放',
                  onPressed: onTogglePause),
              XpIconButton(
                  icon: XpSymbol.close, label: '关闭迷你播放器', onPressed: onClose),
            ])));
  }
}
