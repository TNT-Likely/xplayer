import 'package:adaptive_shell/adaptive_shell.dart';
import 'package:flutter/material.dart';

import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/components/channel_rail.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/utils/channel_filter.dart';

/// 十英尺（电视）首页内容区。
///
/// 与手机端的差别不只是「字大一点」：
///
/// **一、四周留安全边距。** 老电视的过扫描（overscan）会把画面边缘切掉，
/// 贴边的内容在部分机型上直接看不见。5% 是行业惯例。
///
/// **二、只有焦点态，没有悬停态。** 遥控器没有指针，所以每个可操作元素
/// 都必须能被方向键聚焦，且焦点必须一眼看得出来。
///
/// **三、卡片更大、每屏更少。** 观看距离是手机的十倍，信息密度必须降下来。
/// 但也不能太少 —— 面对上千个频道，一屏只看到五个会让换台变成苦差事，
/// 所以用横向轨道而不是大图墙。
class TenFootHomeBody extends StatelessWidget {
  final List<Channel> channels;
  final List<Channel> recentChannels;
  final List<Channel> favoriteChannels;

  const TenFootHomeBody({
    super.key,
    required this.channels,
    required this.recentChannels,
    required this.favoriteChannels,
  });

  /// 过扫描安全边距。老电视会切掉画面边缘，贴边内容可能整块看不见。
  static const double _safeAreaFraction = 0.05;

  /// 电视上一条轨道至少要有几个频道才值得占一行。
  /// 比手机端严一档 —— 每行更贵，不该被两三个频道占掉。
  static const int _minPerRail = 4;

  /// 最多铺几条。遥控器上下翻比手指滑慢得多，超过这个数就该去分组页。
  static const int _maxGroupRails = 6;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final kind = resolveShell(context);
    final cardWidth = channelCardWidth(kind, size.width);
    final inset = size.width * _safeAreaFraction;

    final counts = groupCounts(channels);
    final groups = counts.entries
        .where((e) => e.value >= _minPerRail)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: inset,
        vertical: size.height * _safeAreaFraction,
      ),
      child: ListView(
        children: [
          ChannelRail(
            title: '最近观看',
            channels: recentChannels,
            cardWidth: cardWidth,
          ),
          ChannelRail(
            title: '收藏',
            channels: favoriteChannels,
            cardWidth: cardWidth,
          ),
          for (final g in groups.take(_maxGroupRails))
            ChannelRail(
              title: g.key,
              channels: filterChannels(channels, group: g.key),
              cardWidth: cardWidth,
            ),
        ],
      ),
    );
  }
}

/// 切台浮层（OSD）。
///
/// 直接按数字键或上下键换台时不唤出整个频道浮层，只在左下角闪一条。
/// 这是机顶盒的经典行为，用户的肌肉记忆已经存在，不该重新发明。
class ChannelZapOsd extends StatelessWidget {
  final Channel channel;

  /// 频道号。补零到三位 —— 连按数字时宽度不跳动。
  final int? number;

  /// 正在播什么。没有 EPG 时传 null，整行省略而不是留空。
  final String? programme;

  const ChannelZapOsd({
    super.key,
    required this.channel,
    this.number,
    this.programme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.s16, vertical: AppDimens.s12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppTokens.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (number != null) ...[
            Text(
              number!.toString().padLeft(3, '0'),
              style: TextStyle(
                color: AppTokens.brand,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                height: 1,
              ),
            ),
            const SizedBox(width: AppDimens.s12),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                channel.name.isEmpty ? channel.id : channel.name,
                style: TextStyle(
                  color: AppTokens.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (programme != null && programme!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    programme!,
                    style: TextStyle(
                      color: AppTokens.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
