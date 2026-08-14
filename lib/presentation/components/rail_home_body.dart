import 'package:adaptive_shell/adaptive_shell.dart';
import 'package:flutter/material.dart';

import 'package:xplayer/data/models/channel_model.dart';
import 'package:epg_xmltv/epg_xmltv.dart';
import 'package:xplayer/presentation/components/channel_rail.dart';
import 'package:xplayer/presentation/components/home_hero.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/utils/channel_filter.dart';

/// 轨道式首页内容区。
///
/// 取代原来的「最近 + 收藏 + 全量网格」纵向堆叠：分组不再需要纵向翻找，
/// 每组一条横向轨道。
///
/// **筛选态仍走网格。** 用户按分组或搜索过滤之后，想看的是「符合条件的全部」，
/// 那是网格擅长的事；轨道是无筛选时的浏览态。所以这里只负责浏览态，
/// 筛选态由调用方继续渲染网格 —— 两者不是互斥的替代关系。
class RailHomeBody extends StatelessWidget {
  /// 全部频道（未筛选）。
  final List<Channel> channels;

  final List<Channel> recentChannels;
  final List<Channel> favoriteChannels;

  /// 节目单。用于主视觉的「正在播」与「此刻在播」轨道。
  /// 为空时这两处自动降级，不留空位。
  final List<Programme> programmes;

  /// 注入当前时间，便于测试。
  final DateTime now;

  /// 点某条轨道的「全部 ›」时回调，参数是分组名（收藏/最近传 null）。
  final void Function(String? group)? onSeeAll;

  final void Function(Channel)? onWatch;
  final VoidCallback? onOpenGuide;

  const RailHomeBody({
    super.key,
    required this.channels,
    required this.recentChannels,
    required this.favoriteChannels,
    required this.now,
    this.programmes = const [],
    this.onSeeAll,
    this.onWatch,
    this.onOpenGuide,
  });

  /// 「上次在看」——主视觉承接它。没有最近记录时退回第一个收藏，
  /// 再没有就不显示主视觉（新用户不该看到一张假卡）。
  Channel? get _heroChannel {
    if (recentChannels.isNotEmpty) return recentChannels.first;
    if (favoriteChannels.isNotEmpty) return favoriteChannels.first;
    return null;
  }

  Programme? _nowOn(Channel c) {
    if (programmes.isEmpty) return null;
    final result =
        PlaylistUtil.findCurrentAndNextProgramme(programmes, c.id, now);
    return result.$2;
  }

  /// 「此刻在播」：拿 EPG 横切收藏频道。
  ///
  /// 既然所有频道都在直播，「现在到底在播什么」反而成了最有价值的一栏 ——
  /// 这是把「everything is live」从噪音转成功能。
  /// 没有节目单的频道不进这条轨道。
  List<Channel> get _nowPlaying {
    if (programmes.isEmpty) return const [];
    final pool = favoriteChannels.isNotEmpty ? favoriteChannels : channels;
    return pool.where((c) => _nowOn(c) != null).take(20).toList();
  }

  /// 一条轨道至少要有几个频道才值得单独占一行。
  /// 太少的分组并成「其它」反而更好找。
  static const int _minPerRail = 3;

  /// 最多铺几条分组轨道。再多就该去分组页翻了，首页一直往下滚不是浏览。
  static const int _maxGroupRails = 8;

  @override
  Widget build(BuildContext context) {
    final kind = resolveShell(context);
    final cardWidth =
        channelCardWidth(kind, MediaQuery.sizeOf(context).width);

    final counts = groupCounts(channels);
    // 频道多的分组排前面 —— 它们更可能是用户常看的。
    final groups = counts.entries
        .where((e) => e.value >= _minPerRail)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hero = _heroChannel;
    final nowPlaying = _nowPlaying;

    return Stack(
      children: [
        // 环境光取代原来那张随机模糊大图:同样的视觉分量,
        // 但它跟你正在看的东西有关,而不是一张无关的照片。
        if (hero != null) const AmbientGlow(),
        ListView(
          padding: const EdgeInsets.only(bottom: AppDimens.s24),
          children: [
        if (hero != null)
          HomeHero(
            channel: hero,
            programme: _nowOn(hero),
            now: now,
            onWatch: onWatch == null ? null : () => onWatch!(hero),
            onGuide: onOpenGuide,
          ),
        // 「此刻在播」排第一 —— 全都在直播时,这是最有价值的一栏。
        ChannelRail(
          title: '此刻在播',
          channels: nowPlaying,
          cardWidth: cardWidth,
        ),
        ChannelRail(
          title: '最近观看',
          channels: recentChannels,
          cardWidth: cardWidth,
          onSeeAll: onSeeAll == null ? null : () => onSeeAll!(null),
        ),
        ChannelRail(
          title: '收藏',
          channels: favoriteChannels,
          cardWidth: cardWidth,
          onSeeAll: onSeeAll == null ? null : () => onSeeAll!(null),
        ),
        for (final g in groups.take(_maxGroupRails))
          ChannelRail(
            title: g.key,
            channels: filterChannels(channels, group: g.key),
            cardWidth: cardWidth,
            onSeeAll: onSeeAll == null ? null : () => onSeeAll!(g.key),
          ),
        // 未分类排在最后 —— 它不是一个真实分类，只是「没归到任何组」。
        Builder(builder: (context) {
          final unc = filterChannels(channels, uncategorized: true);
          if (unc.length < _minPerRail) return const SizedBox.shrink();
          return ChannelRail(
            title: '未分类',
            channels: unc,
            cardWidth: cardWidth,
            onSeeAll: onSeeAll == null ? null : () => onSeeAll!(null),
          );
        }),
          ],
        ),
      ],
    );
  }
}
