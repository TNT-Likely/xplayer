import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xplayer/data/models/channel_model.dart';
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

  @override
  void initState() {
    super.initState();
    _hCtrl.addListener(() {
      if (_axisCtrl.hasClients) _axisCtrl.jumpTo(_hCtrl.offset);
    });
    _vCtrl.addListener(() {
      if (_colCtrl.hasClients) _colCtrl.jumpTo(_vCtrl.offset);
    });
    _nowTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
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

  void _scrollToNow() {
    if (!_hCtrl.hasClients) return;
    final media = Provider.of<MediaProvider>(context, listen: false);
    final metrics = EpgMetrics.fromProgrammes(media.programmes, now: _now);
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final media = Provider.of<MediaProvider>(context);
    final metrics = EpgMetrics.fromProgrammes(media.programmes, now: _now);
    final channels = channelsWithEpg(media.channels, media.programmes);

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
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _vCtrl,
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            controller: _hCtrl,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: metrics.contentWidth,
                              height: metrics.rowHeight * channels.length,
                              child: Stack(
                                children: [
                                  ..._blocks(channels, media, metrics),
                                  _nowLine(metrics, channels.length),
                                ],
                              ),
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

  List<Widget> _blocks(
      List<Channel> channels, MediaProvider media, EpgMetrics metrics) {
    final widgets = <Widget>[];
    for (var i = 0; i < channels.length; i++) {
      final c = channels[i];
      final progs = programmesFor(media.programmes, c.id);
      for (final p in progs) {
        widgets.add(Positioned(
          left: metrics.xForTime(p.start),
          top: i * metrics.rowHeight,
          width: metrics.widthForRange(p.start, p.stop),
          height: metrics.rowHeight,
          child: EpgProgrammeBlock(
            programme: p,
            live: isLive(p, _now),
            onTap: () => _openChannel(c, media),
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _nowLine(EpgMetrics metrics, int rows) {
    return Positioned(
      left: metrics.xForTime(_now),
      top: 0,
      height: metrics.rowHeight * rows,
      width: 2,
      child: Container(color: Colors.redAccent),
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
