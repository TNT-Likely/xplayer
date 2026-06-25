import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/widgets/channel_item_widget.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer/localization/app_localizations.dart';

// 与 ChannelListWidget 网格保持一致的布局参数。
const double _kItemSpacing = 8;
const double _kAspectRatio = 16 / 12; // 宽/高

int _crossAxisCount(double maxWidth, int sizeLevel) {
  int base;
  if (maxWidth < 380) {
    base = 2;
  } else if (maxWidth < 570) {
    base = 3;
  } else if (maxWidth < 800) {
    base = 4;
  } else {
    base = 6;
  }
  final count = base + (sizeLevel - 2);
  return count.clamp(2, 12);
}

double _itemWidth(double maxWidth, int sizeLevel) {
  final cross = _crossAxisCount(maxWidth, sizeLevel);
  final usable = maxWidth - (cross - 1) * _kItemSpacing - 2 * _kItemSpacing;
  return usable / cross;
}

/// 首页横向频道行(最近播放 / 收藏 共用)。单项复用 [ChannelItemWidget],与全部频道一致。
Widget _channelRow(
  BuildContext context, {
  required String title,
  required List<Channel> channels,
  required List<Channel> favoriteChannels,
  required int sizeLevel,
  Widget? trailing,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final itemWidth = _itemWidth(constraints.maxWidth, sizeLevel);
      final itemHeight = itemWidth / _kAspectRatio;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
          ),
          SizedBox(
            height: itemHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _kItemSpacing),
              itemCount: channels.length,
              separatorBuilder: (_, __) => const SizedBox(width: _kItemSpacing),
              itemBuilder: (_, i) => SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: ChannelItemWidget(
                  channel: channels[i],
                  favoriteChannels: favoriteChannels,
                  width: itemWidth,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// 「全部频道」小标题:当最近播放行或收藏行可见时显示(与上方留间距),否则不占位。
class AllChannelsHeader extends StatelessWidget {
  const AllChannelsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<MediaProvider>(
      builder: (context, mp, _) {
        return AnimatedBuilder(
          animation: Listenable.merge([showRecentModule, showFavoritesRow]),
          builder: (_, __) {
            final recentVisible =
                showRecentModule.value && mp.recentChannels.isNotEmpty;
            final favVisible =
                showFavoritesRow.value && mp.currentPlaylistFavorites.isNotEmpty;
            if (!recentVisible && !favVisible) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(l.allChannels,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            );
          },
        );
      },
    );
  }
}

/// 首页「最近播放」横向行。空列表或开关关时不显示(不占位)。
class RecentPlayedWidget extends StatelessWidget {
  const RecentPlayedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: showRecentModule,
      builder: (_, show, __) {
        if (!show) return const SizedBox.shrink();
        return Consumer<MediaProvider>(
          builder: (context, mp, ___) {
            final recent = mp.recentChannels;
            if (recent.isEmpty) return const SizedBox.shrink();
            return _channelRow(
              context,
              title: l.recentlyPlayed,
              channels: recent,
              favoriteChannels: mp.favoriteChannels,
              sizeLevel: mp.gridSizeLevel,
              trailing: InkWell(
                onTap: () => mp.clearRecent(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(l.clearAll,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 首页「收藏」横向行:仅显示当前播放列表内的收藏;空时不显示。
class FavoritesRowWidget extends StatelessWidget {
  const FavoritesRowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: showFavoritesRow,
      builder: (_, show, __) {
        if (!show) return const SizedBox.shrink();
        return Consumer<MediaProvider>(
          builder: (context, mp, ___) {
            final favs = mp.currentPlaylistFavorites;
            if (favs.isEmpty) return const SizedBox.shrink();
            return _channelRow(
              context,
              title: l.favorites,
              channels: favs,
              favoriteChannels: mp.favoriteChannels,
              sizeLevel: mp.gridSizeLevel,
            );
          },
        );
      },
    );
  }
}
