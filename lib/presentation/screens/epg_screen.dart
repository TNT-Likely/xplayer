import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/adapters/app_actions.dart';
import 'package:xplayer/presentation/adapters/media_presentation.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/utils/programme_index.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

class EpgScreen extends StatefulWidget {
  const EpgScreen({
    super.key,
    this.embedded = false,
    this.onWatchChannels,
    this.onConfigure,
  });
  final bool embedded;
  final VoidCallback? onWatchChannels, onConfigure;
  @override
  State<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends State<EpgScreen> {
  final _search = TextEditingController();
  Timer? _timer;
  DateTime _now = DateTime.now();
  DateTime? _anchor;
  bool? _timeline;
  int _page = 0;
  static const _pageSize = 20;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _watch() {
    if (widget.onWatchChannels != null) {
      widget.onWatchChannels!();
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _programme(Channel channel, XpProgramme programme) async {
    await showDialog(
      context: context,
      builder: (ctx) => XpConfirmDialog(
        title: programme.title,
        confirmLabel: '观看频道直播',
        onConfirm: () {
          Navigator.pop(ctx);
          AppActions.play(context, channel);
        },
        onCancel: () => Navigator.pop(ctx),
        child: Text(
          '${channel.name}\n${xpDateTime(programme.start)} — ${xpDateTime(programme.end)}\n\n播放入口将打开该频道当前直播。',
        ),
      ),
    );
  }

  Widget _programmeList(Channel c, MediaPresentation presentation, bool stale) {
    final programmes = presentation.index
        .forChannel(c.id)
        .where((p) => stale || p.stop.isAfter(_now))
        .take(3);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: XpSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            XpChannelIdentity(channel: presentation.channel(c)),
            const SizedBox(height: 12),
            for (final programme in programmes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 108,
                  child: XpProgrammeBlock(
                    programme: presentProgramme(programme),
                    now: _now,
                    stale: stale,
                    onPressed: () => _programme(c, presentProgramme(programme)),
                  ),
                ),
              ),
            if (programmes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('暂无匹配的节目信息'),
              ),
            XpButton(
              label: '观看 ${c.name}',
              icon: XpSymbol.play,
              onPressed: () => AppActions.play(context, c),
              variant: XpButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = context.watch<MediaProvider>();
    final presentation = MediaPresentation(media, now: _now);
    final p = XpTheme.of(context).palette;
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 600;
        final timeline = _timeline ?? !compact;
        final channels = media.channels
            .where(
              (c) => '${c.name} ${c.id}'.toLowerCase().contains(
                _search.text.trim().toLowerCase(),
              ),
            )
            .toList();
        final pages = (channels.length / _pageSize).ceil().clamp(1, 100000);
        final page = _page.clamp(0, pages - 1);
        final visible = channels
            .skip(page * _pageSize)
            .take(_pageSize)
            .toList();
        final stale = presentation.epgStatus == XpEpgStatus.stale;
        final base =
            _anchor ??
            (stale
                ? presentation.coverageEnd?.subtract(const Duration(hours: 2))
                : _now) ??
            _now;
        final start = epgWindowStart(base);
        final end = start.add(const Duration(hours: 3));
        final owners = <XpProgramme, Channel>{};
        final rows = [
          for (final c in visible)
            XpEpgRowData(
              channel: presentation.channel(c),
              programmes: [
                for (final programme in presentation.index.forChannel(c.id))
                  if (programme.stop.isAfter(start) &&
                      programme.start.isBefore(end))
                    (() {
                      final ui = presentProgramme(programme);
                      owners[ui] = c;
                      return ui;
                    })(),
              ],
            ),
        ];
        final content = SingleChildScrollView(
          key: const PageStorageKey('epg-scroll'),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              XpSearchField(
                controller: _search,
                hint: '查找频道节目单',
                onChanged: (_) => setState(() => _page = 0),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  XpChip(
                    label: '节目列表',
                    selected: !timeline,
                    onPressed: () => setState(() => _timeline = false),
                  ),
                  XpChip(
                    label: '时间轴',
                    selected: timeline,
                    onPressed: () => setState(() => _timeline = true),
                  ),
                  XpButton(
                    label: '现在',
                    onPressed: () => setState(() {
                      _anchor = null;
                      _now = DateTime.now();
                    }),
                    variant: XpButtonVariant.secondary,
                  ),
                  XpIconButton(
                    icon: XpSymbol.sync,
                    label: '刷新节目单',
                    onPressed: media.isRefreshingProgrammes
                        ? null
                        : media.refreshProgrammes,
                  ),
                  if (timeline) ...[
                    XpButton(
                      label: '前 3 小时',
                      onPressed: () => setState(
                        () =>
                            _anchor = start.subtract(const Duration(hours: 3)),
                      ),
                      variant: XpButtonVariant.ghost,
                    ),
                    XpButton(
                      label: '后 3 小时',
                      onPressed: () => setState(() => _anchor = end),
                      variant: XpButtonVariant.ghost,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${start.month} 月 ${start.day} 日 · ${xpTime(start)} — ${xpTime(end)}',
                style: TextStyle(color: p.muted),
              ),
              const SizedBox(height: 18),
              if (channels.isEmpty && _search.text.isNotEmpty)
                XpEmptyState(
                  title: '没有匹配的频道',
                  description: '换一个关键词，或清除搜索。',
                  icon: XpSymbol.search,
                  actionLabel: '清除搜索',
                  onAction: () => setState(_search.clear),
                )
              else
                XpEpgStateView(
                  status: presentation.epgStatus,
                  cachedAt: presentation.cachedAt,
                  coverageEnd: presentation.coverageEnd,
                  now: _now,
                  missingCount: presentation.missingCount,
                  onWatch: _watch,
                  onRetry: media.isRefreshingProgrammes
                      ? null
                      : media.refreshProgrammes,
                  onConfigure:
                      widget.onConfigure ??
                      () => Navigator.pushNamed(context, '/playlists'),
                  child: timeline
                      ? XpEpgTimeline(
                          rows: rows,
                          start: start,
                          end: end,
                          now: _now,
                          stale: stale,
                          onWatchChannel: (channel) => AppActions.play(
                            context,
                            visible.firstWhere((c) => c.id == channel.id),
                          ),
                          onProgramme: (programme) =>
                              _programme(owners[programme]!, programme),
                        )
                      : Column(
                          children: [
                            for (final c in visible)
                              _programmeList(c, presentation, stale),
                          ],
                        ),
                ),
              if (pages > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      XpButton(
                        label: '上一页',
                        onPressed: page == 0
                            ? null
                            : () => setState(() => _page = page - 1),
                        variant: XpButtonVariant.secondary,
                      ),
                      Text('${page + 1} / $pages'),
                      XpButton(
                        label: '下一页',
                        onPressed: page == pages - 1
                            ? null
                            : () => setState(() => _page = page + 1),
                        variant: XpButtonVariant.secondary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
        return widget.embedded
            ? content
            : Scaffold(
                appBar: AppBar(title: const Text('节目单')),
                body: content,
              );
      },
    );
  }
}
