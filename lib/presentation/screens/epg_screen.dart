import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/presentation/widgets/epg_channel_column.dart';
import 'package:xplayer/presentation/widgets/epg_programme_block.dart';
import 'package:xplayer/presentation/widgets/epg_time_axis.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/utils/epg_metrics.dart';

class EpgScreen extends StatefulWidget {
  const EpgScreen({super.key});

  @override
  State<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends State<EpgScreen> {
  final ScrollController _hCtrl = ScrollController(); // 主区横向(时间)
  final ScrollController _vCtrl = ScrollController(); // 主区纵向(频道)
  final ScrollController _axisCtrl = ScrollController(); // 时间轴,跟随 _hCtrl
  final ScrollController _colCtrl = ScrollController(); // 频道列,跟随 _vCtrl
  Timer? _nowTimer;
  DateTime _now = DateTime.now();
  bool _scrolledToNow = false;

  @override
  void initState() {
    super.initState();
    _hCtrl.addListener(() {
      if (_axisCtrl.hasClients && _axisCtrl.offset != _hCtrl.offset) {
        _axisCtrl.jumpTo(_hCtrl.offset);
      }
    });
    _vCtrl.addListener(() {
      if (_colCtrl.hasClients && _colCtrl.offset != _vCtrl.offset) {
        _colCtrl.jumpTo(_vCtrl.offset);
      }
    });
    // 每分钟只刷新「现在线」位置,setState 很轻(行是懒构建的)
    _nowTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _nowTimer?.cancel();
    _hCtrl.dispose();
    _vCtrl.dispose();
    _axisCtrl.dispose();
    _colCtrl.dispose();
    super.dispose();
  }

  void _scrollToNow(EpgMetrics metrics) {
    if (_scrolledToNow || !_hCtrl.hasClients) return;
    _scrolledToNow = true;
    final target = (metrics.xForTime(_now) - 80)
        .clamp(0.0, _hCtrl.position.maxScrollExtent);
    _hCtrl.jumpTo(target);
  }

  void _openChannel(Channel c, MediaProvider media) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(
        channel: c,
        favoriteChannels: media.favoriteChannels,
      ),
    ));
  }

  /// 一次性把所有节目按频道分组并排序(O(n)),避免每行 O(n) 过滤造成 O(频道×节目)。
  Map<String, List<Programme>> _groupByChannel(List<Programme> all) {
    final map = <String, List<Programme>>{};
    for (final p in all) {
      (map[p.channel.toLowerCase()] ??= <Programme>[]).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final media = Provider.of<MediaProvider>(context);
    final metrics = EpgMetrics.fromProgrammes(media.programmes, now: _now);
    final channels = channelsWithEpg(media.channels, media.programmes);
    final grouped = _groupByChannel(media.programmes);
    final nowX = metrics.xForTime(_now);

    // 首帧后定位到此刻(只做一次)
    if (channels.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToNow(metrics));
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l.epg, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: channels.isEmpty
          ? _empty(l)
          : Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                        width: metrics.channelColWidth,
                        height: metrics.timeAxisHeight),
                    Expanded(
                      child:
                          EpgTimeAxis(metrics: metrics, controller: _axisCtrl),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    children: [
                      EpgChannelColumn(
                        channels: channels,
                        metrics: metrics,
                        controller: _colCtrl,
                      ),
                      // 主区:横向滚一个固定宽容器,内部纵向 ListView.builder 懒构建频道行
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _hCtrl,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: metrics.contentWidth,
                            child: ListView.builder(
                              controller: _vCtrl,
                              itemExtent: metrics.rowHeight,
                              itemCount: channels.length,
                              itemBuilder: (ctx, i) {
                                final c = channels[i];
                                final progs =
                                    grouped[c.id.toLowerCase()] ?? const [];
                                return _row(c, progs, metrics, nowX, media);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _row(Channel c, List<Programme> progs, EpgMetrics metrics,
      double nowX, MediaProvider media) {
    return SizedBox(
      width: metrics.contentWidth,
      height: metrics.rowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final p in progs)
            Positioned(
              left: metrics.xForTime(p.start),
              top: 0,
              width: metrics.widthForRange(p.start, p.stop),
              height: metrics.rowHeight,
              child: EpgProgrammeBlock(
                programme: p,
                live: isLive(p, _now),
                onTap: () => _openChannel(c, media),
              ),
            ),
          // 本行的「现在」线段(各行对齐 → 视觉上连成一条竖线)
          Positioned(
            left: nowX,
            top: 0,
            height: metrics.rowHeight,
            width: 2,
            child: Container(color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(l.epgEmptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text(l.epgEmptyHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
