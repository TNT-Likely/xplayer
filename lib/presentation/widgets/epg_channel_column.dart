import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/utils/epg_metrics.dart';

/// 左侧固定频道列。纵向滚动由外部 [controller] 驱动(与主区同步,本身不可独立滚)。
class EpgChannelColumn extends StatelessWidget {
  final List<Channel> channels;
  final EpgMetrics metrics;
  final ScrollController controller;

  const EpgChannelColumn({
    super.key,
    required this.channels,
    required this.metrics,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: metrics.channelColWidth,
      child: ListView.builder(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: channels.length,
        itemBuilder: (context, i) {
          final c = channels[i];
          return Container(
            height: metrics.rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
                right: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: (c.logo != null && c.logo!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: c.logo!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.live_tv,
                              color: Colors.white54,
                              size: 22),
                        )
                      : const Icon(Icons.live_tv,
                          color: Colors.white54, size: 22),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.name.isNotEmpty ? c.name : c.id,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
