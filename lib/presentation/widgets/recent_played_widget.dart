import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer/localization/app_localizations.dart';

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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Text(l.recentlyPlayed,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      InkWell(
                        onTap: () => mp.clearRecent(),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(l.clearAll,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final Channel c = recent[i];
                      return XBaseButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(
                                channel: c,
                                favoriteChannels: mp.favoriteChannels,
                              ),
                            ),
                          );
                        },
                        onMore: () => mp.removeRecent(c.id),
                        child: (isFocused) => SizedBox(
                          width: 120,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                    border: isFocused
                                        ? Border.all(
                                            color: Colors.white, width: 2)
                                        : null,
                                  ),
                                  child: (c.logo != null && c.logo!.isNotEmpty)
                                      ? Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: CachedNetworkImage(
                                            imageUrl: c.logo!,
                                            fit: BoxFit.contain,
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.live_tv,
                                                    color: Colors.white54),
                                          ),
                                        )
                                      : const Icon(Icons.live_tv,
                                          color: Colors.white54),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
