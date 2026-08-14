import 'package:flutter/material.dart';

import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/widgets/channel_item_widget.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 横向频道轨道。
///
/// 卡片直接复用 [ChannelItemWidget] —— 点击播放、长按菜单、焦点态、
/// 收藏心标、以及标题区的自适应高度全都跟着继承，不另起一套。
/// 轨道与网格的差别只有「排布方向」，不该是两份卡片实现。
///
/// 高度由 [cardWidth] 推出：卡片比例与网格一致（16:12），
/// 这样同一张卡在轨道和网格里看起来是同一个东西。
class ChannelRail extends StatelessWidget {
  final String title;

  final List<Channel> channels;

  /// 卡片宽度。由 `channelCardWidth(shellKind, screenWidth)` 给出，
  /// 组件本身不判断平台。
  final double cardWidth;

  /// 右上角的「全部 ›」。为 null 时不显示。
  final VoidCallback? onSeeAll;

  /// 副行文案生成器。默认走卡片自己的分组·地区；
  /// 「此刻在播」这类轨道可以传入 EPG 节目名覆盖它。
  final String Function(Channel)? subtitleOf;

  const ChannelRail({
    super.key,
    required this.title,
    required this.channels,
    required this.cardWidth,
    this.onSeeAll,
    this.subtitleOf,
  });

  /// 与 `channel_list_widget` 的 childAspectRatio 保持一致。
  static const double _aspect = 16 / 12;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const SizedBox.shrink();

    final cardHeight = cardWidth / _aspect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.s16, AppDimens.s16, AppDimens.s16, AppDimens.s8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTokens.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppDimens.s8),
              Text(
                '${channels.length}',
                style: const TextStyle(
                  color: AppTokens.textTertiary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: const Text(
                    '全部 ›',
                    style: TextStyle(
                        color: AppTokens.textSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
            itemCount: channels.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppDimens.s8),
            itemBuilder: (context, i) => SizedBox(
              width: cardWidth,
              child: ChannelItemWidget(
                channel: channels[i],
                width: cardWidth,
                favoriteChannels: const [],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
