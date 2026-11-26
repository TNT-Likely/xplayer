import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../foundation.dart';
import '../localization/ui_strings.dart';
import 'channel.dart';
import 'models.dart';

class _EpgScope extends InheritedWidget {
  const _EpgScope({required this.stale, required super.child});
  final bool stale;
  static bool isStale(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EpgScope>()?.stale ?? false;
  @override
  bool updateShouldNotify(_EpgScope oldWidget) => oldWidget.stale != stale;
}

class XpProgrammeBlock extends StatelessWidget {
  const XpProgrammeBlock(
      {super.key,
      required this.programme,
      required this.now,
      this.onPressed,
      this.stale = false});
  final XpProgramme programme;
  final DateTime now;
  final VoidCallback? onPressed;
  final bool stale;
  @override
  Widget build(BuildContext context) {
    final l = context.xpStrings;
    final theme = XpTheme.of(context), p = theme.palette;
    final isStale = stale || _EpgScope.isStale(context);
    final current = !isStale && programme.isCurrent(now);
    final timing = programme.hasValidRange
        ? l.programmeTimeRange(xpTime(programme.start), xpTime(programme.end))
        : l.programmeTimeUnavailable;
    final label = l.programmeSemantics(programme.title, timing);
    return Semantics(
        button: onPressed != null,
        label: isStale ? l.cachedProgrammeSemantics(label) : label,
        child: Material(
          color: current ? p.raised : p.background,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                  color: current ? p.accent.withValues(alpha: .45) : p.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onPressed,
              child: LayoutBuilder(builder: (context, box) {
                final scale = MediaQuery.textScalerOf(context);
                final requiredHeight = scale.scale(theme.smallSize) * 2.6 +
                    scale.scale(theme.bodySize) * 1.4 +
                    33;
                final compact =
                    box.maxWidth < 130 || box.maxHeight < requiredHeight;
                return Padding(
                    padding: EdgeInsets.all(compact ? 6 : 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!compact)
                            Text(
                                programme.hasValidRange
                                    ? '${xpTime(programme.start)} — ${xpTime(programme.end)}'
                                    : l.programmeTimeUnavailable,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: theme.smallSize, color: p.muted)),
                          const SizedBox(height: 4),
                          Text(programme.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: theme.bodySize,
                                  fontWeight: FontWeight.w500,
                                  color: p.foreground)),
                          if (!compact) ...[
                            const SizedBox(height: 5),
                            Text(
                                isStale
                                    ? l.cachedProgramme
                                    : current
                                        ? l.onAir
                                        : l.scheduledProgramme,
                                style: TextStyle(
                                    fontSize: theme.smallSize,
                                    color: current ? p.accent : p.muted))
                          ],
                        ]));
              })),
        ));
  }
}

/// 时间比例来自真实起止时间；超出窗口的部分裁切，非法区间不绘制。
class XpEpgTimeline extends StatelessWidget {
  const XpEpgTimeline(
      {super.key,
      required this.rows,
      required this.start,
      required this.end,
      required this.now,
      this.stale = false,
      this.onWatchChannel,
      this.onProgramme,
      this.pixelsPerMinute = 6});
  final List<XpEpgRowData> rows;
  final DateTime start, end, now;
  final bool stale;
  final ValueChanged<XpChannelData>? onWatchChannel;
  final ValueChanged<XpProgramme>? onProgramme;
  final double pixelsPerMinute;
  @override
  Widget build(BuildContext context) {
    final l = context.xpStrings;
    if (!end.isAfter(start)) {
      return XpNotice(
          title: l.invalidDateRange,
          description: l.invalidDateRangeHint,
          tone: XpTone.warning);
    }
    final theme = XpTheme.of(context), p = theme.palette;
    final channelWidth = theme.isTv ? 230.0 : 170.0;
    final rowHeight = theme.isTv ? 136.0 : 108.0;
    final isStale = stale || _EpgScope.isStale(context);
    final minuteWidth =
        pixelsPerMinute.isFinite && pixelsPerMinute > 0 ? pixelsPerMinute : 6.0;
    final minutes = end.difference(start).inMilliseconds / 60000;
    return LayoutBuilder(builder: (context, box) {
      final width =
          math.max(box.maxWidth, channelWidth + minutes * minuteWidth);
      final timelineWidth = width - channelWidth;
      double offset(DateTime t) =>
          t.difference(start).inMilliseconds /
          end.difference(start).inMilliseconds *
          timelineWidth;
      final ticks = <Widget>[];
      for (var minute = 0; minute <= minutes; minute += 30) {
        final time = start.add(Duration(minutes: minute));
        final local = time.toLocal();
        final label = local.day != start.toLocal().day
            ? '${local.month}/${local.day} ${xpTime(time)}'
            : xpTime(time);
        ticks.add(Positioned(
            left: channelWidth + minute / minutes * timelineWidth + 8,
            top: 15,
            child: Text(label,
                style: TextStyle(fontSize: theme.smallSize, color: p.muted))));
      }
      return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                  width: width,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: p.surface, border: Border.all(color: p.border)),
                    child: Column(children: [
                      SizedBox(
                          height: 52,
                          child: ClipRect(
                              child: Stack(children: [
                            Positioned(
                                left: 16,
                                top: 15,
                                child: Text(l.channelHeading,
                                    style: TextStyle(
                                        color: p.muted,
                                        fontSize: theme.smallSize))),
                            ...ticks
                          ]))),
                      ...rows.map((row) => SizedBox(
                          height: rowHeight,
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  border:
                                      Border(top: BorderSide(color: p.border))),
                              child: Stack(children: [
                                Positioned(
                                    left: 12,
                                    top: 0,
                                    bottom: 0,
                                    width: channelWidth - 24,
                                    child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: XpChannelIdentity(
                                            channel: row.channel))),
                                if (row.programmes.isEmpty)
                                  Positioned(
                                      left: channelWidth + 12,
                                      right: 16,
                                      top: 12,
                                      bottom: 12,
                                      child: Row(children: [
                                        Expanded(
                                            child: Text(l.noProgrammeInfo,
                                                style: TextStyle(
                                                    color: p.muted,
                                                    fontSize: theme.bodySize))),
                                        XpButton(
                                            label: l.watchChannel,
                                            icon: XpSymbol.play,
                                            onPressed: onWatchChannel == null
                                                ? null
                                                : () => onWatchChannel!(
                                                    row.channel),
                                            variant: XpButtonVariant.ghost)
                                      ])),
                                for (final programme in row.programmes.where(
                                    (p) =>
                                        p.hasValidRange &&
                                        p.end.isAfter(start) &&
                                        p.start.isBefore(end)))
                                  Positioned(
                                      left: channelWidth +
                                          math.max(0, offset(programme.start)) +
                                          4,
                                      width: math.max(
                                          1,
                                          math.min(timelineWidth,
                                                  offset(programme.end)) -
                                              math.max(
                                                  0, offset(programme.start)) -
                                              8),
                                      top: 6,
                                      bottom: 6,
                                      child: XpProgrammeBlock(
                                          programme: programme,
                                          now: now,
                                          stale: isStale,
                                          onPressed: onProgramme == null
                                              ? null
                                              : () => onProgramme!(programme))),
                                if (!isStale &&
                                    !now.isBefore(start) &&
                                    now.isBefore(end))
                                  Positioned(
                                      left: channelWidth + offset(now),
                                      top: 0,
                                      bottom: 0,
                                      child: Semantics(
                                          label: l.currentTime(xpTime(now)),
                                          child: Container(
                                              width: 1, color: p.accent))),
                              ])))),
                    ]),
                  ))));
    });
  }
}

class XpEpgStateView extends StatelessWidget {
  const XpEpgStateView(
      {super.key,
      required this.status,
      required this.onWatch,
      this.onRetry,
      this.onConfigure,
      this.cachedAt,
      this.coverageEnd,
      this.now,
      this.missingCount = 0,
      this.child});
  final XpEpgStatus status;
  final VoidCallback onWatch;
  final VoidCallback? onRetry, onConfigure;
  final DateTime? cachedAt, coverageEnd, now;
  final int missingCount;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final l = context.xpStrings;
    // 有缓存但覆盖区间已结束时，不把它标成可用的当前节目单。
    final effective = status == XpEpgStatus.errorWithCache &&
            now != null &&
            coverageEnd != null &&
            !coverageEnd!.isAfter(now!)
        ? XpEpgStatus.stale
        : status;
    if (effective == XpEpgStatus.ready) return child ?? const SizedBox.shrink();
    final (title, body, action) = switch (effective) {
      XpEpgStatus.loading => (
          l.loadingGuide,
          l.loadingGuideHint,
          l.watchWhileLoading
        ),
      XpEpgStatus.unconfigured => (
          l.noGuideConfigured,
          l.noGuideConfiguredHint,
          l.configureGuide
        ),
      XpEpgStatus.empty => (l.guideEmpty, l.guideEmptyHint, l.refreshGuide),
      XpEpgStatus.error => (
          l.guideUnavailable,
          l.guideUnavailableHint,
          l.fetchAgain
        ),
      XpEpgStatus.errorWithCache => (
          l.guideUsingCache,
          cachedAt == null
              ? l.guideCacheHint
              : l.guideCacheDateHint(
                  xpDateTime(cachedAt!, locale: l.localeName)),
          l.retryUpdate
        ),
      XpEpgStatus.stale => (
          l.guideStale,
          cachedAt == null
              ? l.guideStaleHint
              : l.guideStaleDateHint(
                  xpDateTime(cachedAt!, locale: l.localeName)),
          l.updateGuide
        ),
      XpEpgStatus.partial => (
          l.guideMissingChannels(missingCount),
          l.guideMissingChannelsHint,
          l.matchAgain
        ),
      XpEpgStatus.ready => ('', '', ''),
    };
    final callback = effective == XpEpgStatus.loading
        ? onWatch
        : effective == XpEpgStatus.unconfigured
            ? onConfigure
            : onRetry;
    if (effective.retainsContent) {
      return _EpgScope(
          stale: effective == XpEpgStatus.stale,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            XpNotice(
                title: title,
                description: body,
                tone: effective == XpEpgStatus.partial
                    ? XpTone.neutral
                    : XpTone.warning,
                actionLabel: action,
                onAction: callback),
            if (child != null) ...[const SizedBox(height: 18), child!],
          ]));
    }
    return XpEmptyState(
        title: title,
        description: body,
        icon: effective == XpEpgStatus.error ? XpSymbol.info : XpSymbol.guide,
        loading: effective == XpEpgStatus.loading,
        tone: effective == XpEpgStatus.error ? XpTone.error : XpTone.neutral,
        // 加载时仍允许独立的观看操作，不把重试按钮重复提交。
        actionLabel: effective == XpEpgStatus.loading ? null : action,
        onAction: callback,
        secondaryLabel: l.browseChannels,
        onSecondary: onWatch);
  }
}
