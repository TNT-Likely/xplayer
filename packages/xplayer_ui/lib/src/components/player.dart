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
      this.onSwitchChannel,
      this.onCancel,
      this.detail,
      this.paused = false,
      this.onToggleAudio});
  final XpPlaybackPhase phase;
  final String channelName;
  final String? detail;
  final VoidCallback? onRetry, onSwitchChannel, onCancel, onToggleAudio;
  final bool paused;
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
          '这个频道暂时无法播放',
          detail ?? '连接已中断；已停止自动重试。可以重连或切换频道。',
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
          '$channelName · ${paused ? '准备好后可以继续收听' : '声音正在播放，不显示黑屏错误'}',
          paused ? '继续音频' : '暂停音频',
          XpSymbol.volume
        ),
      _ => ('', '', '', XpSymbol.info),
    };
    final callback = phase == XpPlaybackPhase.connecting
        ? onCancel
        : phase == XpPlaybackPhase.audioOnly
            ? onToggleAudio
            : onRetry;
    return XpEmptyState(
      title: title,
      description: copy,
      icon: icon,
      tone:
          phase == XpPlaybackPhase.error || phase == XpPlaybackPhase.unsupported
              ? XpTone.error
              : XpTone.neutral,
      actionLabel: label,
      onAction: callback,
      secondaryLabel: onSwitchChannel == null ? null : '切换频道',
      onSecondary: onSwitchChannel,
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
