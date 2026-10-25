import 'package:flutter/material.dart';
import '../../foundation.dart';
import 'models.dart';

class XpChannelIdentity extends StatelessWidget {
  const XpChannelIdentity(
      {super.key, required this.channel, this.showName = true});
  final XpChannelData channel;
  final bool showName;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
          child: Container(
        constraints: const BoxConstraints(minWidth: 40),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
            color: p.accentWash,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(4)),
        child: Text(
            channel.logoLabel ?? channel.name.characters.take(4).toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: p.accent,
                fontSize: theme.smallSize,
                fontWeight: FontWeight.w600)),
      )),
      if (showName) ...[
        const SizedBox(width: 10),
        Flexible(
            child: Text(channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: theme.bodySize, color: p.foreground)))
      ],
    ]);
  }
}

class XpArtwork extends StatelessWidget {
  const XpArtwork({super.key, required this.channel});
  final XpChannelData channel;
  @override
  Widget build(BuildContext context) {
    final p = XpTheme.of(context).palette;
    final fallback = ColoredBox(
        color: p.raised,
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          XpIcon(XpSymbol.channels, size: 34, color: p.quiet),
          const SizedBox(height: 12),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(channel.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted))),
        ])));
    if (channel.artwork == null) return fallback;
    return Image(
        image: channel.artwork!,
        fit: BoxFit.cover,
        width: double.infinity,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => fallback);
  }
}

class XpLiveBadge extends StatelessWidget {
  const XpLiveBadge({super.key, this.live = true});
  final bool live;
  @override
  Widget build(BuildContext context) => XpBadge(live ? 'LIVE' : '离线',
      dot: live, tone: live ? XpTone.success : XpTone.warning);
}

class XpFavouriteButton extends StatelessWidget {
  const XpFavouriteButton(
      {super.key,
      required this.channelName,
      required this.value,
      required this.onChanged});
  final String channelName;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => XpIconButton(
        icon: XpSymbol.heart,
        label: '${value ? '取消收藏' : '收藏'} $channelName',
        selected: value,
        onPressed: onChanged == null ? null : () => onChanged!(!value),
      );
}

class XpChannelCard extends StatelessWidget {
  const XpChannelCard(
      {super.key,
      required this.channel,
      required this.now,
      required this.onPlay,
      this.favourite = false,
      this.onFavouriteChanged,
      this.epgStatus = XpEpgStatus.ready,
      this.offline = false});
  final XpChannelData channel;
  final DateTime now;
  final VoidCallback? onPlay;
  final bool favourite, offline;
  final ValueChanged<bool>? onFavouriteChanged;
  final XpEpgStatus epgStatus;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    final programme = epgStatus.hasCurrentMetadata ? channel.programme : null;
    final current = programme?.isCurrent(now) ?? false;
    return XpSurface(
        padding: EdgeInsets.zero,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(fit: StackFit.expand, children: [
                        XpArtwork(channel: channel),
                        const DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                              Colors.transparent,
                              Color(0xcc07100b)
                            ]))),
                        Positioned.fill(
                            child: Semantics(
                                button: true,
                                label: '观看 ${channel.name}',
                                child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                        onTap: onPlay,
                                        focusColor: p.accentWash,
                                        hoverColor: p.accentWash,
                                        child: const SizedBox.expand())))),
                        Positioned(
                            top: 10,
                            left: 10,
                            child: IgnorePointer(
                                child: XpLiveBadge(live: !offline))),
                        if (channel.quality != null)
                          Positioned(
                              top: 10,
                              right: 8,
                              child: IgnorePointer(
                                  child: XpBadge(channel.quality!))),
                        Positioned(
                            left: 14,
                            right: 14,
                            bottom: 14,
                            child: IgnorePointer(
                                child: Text(programme?.title ?? channel.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: theme.isTv ? 24 : 20,
                                        color: p.foreground,
                                        fontWeight: FontWeight.w500)))),
                      ]))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: XpChannelIdentity(channel: channel)),
                          XpFavouriteButton(
                              channelName: channel.name,
                              value: favourite,
                              onChanged: onFavouriteChanged)
                        ]),
                        const SizedBox(height: 4),
                        Text(
                            programme?.title ??
                                (epgStatus == XpEpgStatus.stale
                                    ? '节目单已过期'
                                    : '暂无节目单'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: theme.bodySize, color: p.muted)),
                        if (programme != null && programme.hasValidRange) ...[
                          if (current) ...[
                            const SizedBox(height: 12),
                            XpProgress(
                                value: programme.progressAt(now)!,
                                label: '${programme.title} 节目进度')
                          ],
                          const SizedBox(height: 9),
                          Text(
                              '${xpTime(programme.start)} — ${xpTime(programme.end)}',
                              style: TextStyle(
                                  fontSize: theme.smallSize, color: p.muted)),
                        ],
                      ])),
            ]));
  }
}

class XpFeaturedChannel extends StatelessWidget {
  const XpFeaturedChannel(
      {super.key,
      required this.channel,
      required this.now,
      required this.onPlay,
      this.epgStatus = XpEpgStatus.ready,
      this.favourite = false,
      this.onFavouriteChanged,
      this.onDetails,
      this.englishTitle});
  final XpChannelData channel;
  final DateTime now;
  final XpEpgStatus epgStatus;
  final VoidCallback? onPlay, onDetails;
  final ValueChanged<bool>? onFavouriteChanged;
  final bool favourite;
  final String? englishTitle;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    final programme = epgStatus.hasCurrentMetadata ? channel.programme : null;
    return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(children: [
          Positioned.fill(child: XpArtwork(channel: channel)),
          const Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Color(0x3307100b), Color(0xef07100b)])))),
          Padding(
              padding: EdgeInsets.all(theme.device == XpDevice.phone ? 22 : 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const XpLiveBadge(),
                      const Spacer(),
                      XpFavouriteButton(
                          channelName: channel.name,
                          value: favourite,
                          onChanged: onFavouriteChanged)
                    ]),
                    SizedBox(height: theme.isTv ? 100 : 60),
                    XpChannelIdentity(channel: channel),
                    const SizedBox(height: 18),
                    Text(programme?.title ?? channel.name,
                        style: TextStyle(
                            fontSize: theme.isTv
                                ? 60
                                : theme.device == XpDevice.phone
                                    ? 36
                                    : 44,
                            color: p.foreground,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: -1)),
                    if (englishTitle != null && programme != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(englishTitle!,
                              style: TextStyle(
                                  fontSize: theme.isTv ? 32 : 24,
                                  fontFamily: 'serif',
                                  fontStyle: FontStyle.italic,
                                  color: p.muted))),
                    const SizedBox(height: 16),
                    Text(
                        programme?.subtitle ??
                            (programme == null ? '暂无节目单 · 频道仍可播放' : ''),
                        style: TextStyle(
                            color: p.muted, fontSize: theme.bodySize)),
                    const SizedBox(height: 22),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      XpButton(
                          label: '立即观看',
                          icon: XpSymbol.play,
                          onPressed: onPlay),
                      if (onDetails != null && programme != null)
                        XpButton(
                            label: '节目详情',
                            onPressed: onDetails,
                            variant: XpButtonVariant.ghost)
                    ]),
                    if (programme != null && programme.isCurrent(now)) ...[
                      const SizedBox(height: 24),
                      Text(
                          '${xpTime(programme.start)} — ${xpTime(programme.end)}',
                          style: TextStyle(
                              color: p.muted, fontSize: theme.smallSize)),
                      const SizedBox(height: 12),
                      XpProgress(value: programme.progressAt(now)!)
                    ],
                  ])),
        ]));
  }
}

class XpSectionHeading extends StatelessWidget {
  const XpSectionHeading(
      {super.key, required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context);
    return Row(children: [
      Expanded(
          child: Text(title,
              style: TextStyle(
                  fontSize: theme.titleSize, fontWeight: FontWeight.w500))),
      if (actionLabel != null)
        XpButton(
            label: actionLabel!,
            onPressed: onAction,
            variant: XpButtonVariant.ghost)
    ]);
  }
}
