import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/channel_test_result.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/utils/epg_index.dart';

/// 首页「大直播卡」(方向 A · ON AIR 演播室):
/// 打开即回答现在播什么、播到哪、下一档是什么。
///
/// - 画面区:频道台标 + LIVE 徽章 + 测速角标,点击进全屏播放;
/// - 信息层:频道名 + 分组 + 收藏,当前节目 + 进度条 + 剩余时间 + 下一档。
///
/// [channel] 由调用方决定(小窗续播频道 > 最近播放第一条 > 频道列表首个);
/// EPG 查询走 [MediaProvider.epgIndex](refreshProgrammes 后构建的 O(log n) 索引)。
///
/// 高度自适应:手机竖屏滚动区内无界 → 画面区固定 16:9;
/// 宽屏/横屏下外层用 ConstrainedBox 限高 → 画面区改弹性填充(cover 裁切),
/// 避免 16:9 固定比例把信息层挤出屏幕(TV 1080p 横屏实测曾溢出 174px)。
class HeroLiveCard extends StatelessWidget {
  final Channel channel;
  final List<Channel> favoriteChannels;

  const HeroLiveCard({
    super.key,
    required this.channel,
    required this.favoriteChannels,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mp = Provider.of<MediaProvider>(context);
    final now = DateTime.now();
    final epg = mp.epgIndex;
    final current = epg.currentFor(channel.id, now);
    final next = epg.nextFor(channel.id, now);
    final progress = EpgIndex.progressOf(current, now);
    final isFavorite =
        favoriteChannels.any((element) => element.id == channel.id);
    final group =
        channel.source.isNotEmpty ? channel.source.first.groupTitle : '';
    final testResult = mp.getChannelTestResult(channel.id);

    final infoLayer = Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  channel.name.isNotEmpty ? channel.name : channel.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (group.isNotEmpty)
                Text(group,
                    style: const TextStyle(
                        color: AppTokens.textTertiary, fontSize: 11)),
              const SizedBox(width: 8),
              _FavoriteButton(
                isFavorite: isFavorite,
                onToggle: () => mp.toggleFavorite(channel),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            current != null ? current.title : l.noProgramme,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppTokens.textSecondary, fontSize: 13),
          ),
          if (progress != null && current != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(AppTokens.brand),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _hm(current.start),
                  style: const TextStyle(
                      color: AppTokens.textTertiary,
                      fontSize: 10,
                      fontFamily: 'monospace'),
                ),
                Expanded(
                  child: Text(
                    _remainText(l, current, now),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTokens.textTertiary, fontSize: 10),
                  ),
                ),
                Text(
                  _hm(current.stop),
                  style: const TextStyle(
                      color: AppTokens.textTertiary,
                      fontSize: 10,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
          if (next != null) ...[
            const SizedBox(height: 6),
            Text(
              '${l.upNext} ${_hm(next.start)} ${next.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTokens.textTertiary, fontSize: 11),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surfacePanel,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: Colors.white12),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bounded = constraints.maxHeight.isFinite;
            final pic = XBaseButton(
              onPressed: () => _openPlayer(context),
              child: (isFocused) {
                final layers = Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPictureArea(context, isFocused),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFFF453A),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            const Text('LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontFamily: 'monospace',
                                )),
                          ],
                        ),
                      ),
                    ),
                    if (testResult != null &&
                        testResult.status == TestStatus.success)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusSm),
                          ),
                          child: Text('${testResult.latency}ms',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    if (isFocused)
                      Container(
                        color: AppTokens.focusPlayOverlay,
                        child: const Center(
                          child: Icon(Icons.play_circle,
                              color: Colors.white, size: 64),
                        ),
                      ),
                  ],
                );
                return bounded
                    ? SizedBox.expand(child: layers)
                    : AspectRatio(aspectRatio: 16 / 9, child: layers);
              },
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                bounded ? Flexible(child: pic) : pic,
                infoLayer,
              ],
            );
          },
        ),
      ),
    );
  }

  /// 画面区底图:台标或回退图标(cover 填充时由 Container 裁切)。
  Widget _buildPictureArea(BuildContext context, bool isFocused) {
    final logo = channel.logo;
    return Container(
      color: AppTokens.surfaceThumb,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: (logo == null || logo.isEmpty)
          ? Icon(
              Icons.live_tv,
              color: isFocused ? Colors.white : Colors.white70,
              size: 56,
            )
          : CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Icon(
                Icons.live_tv,
                color: Colors.white70,
                size: 56,
              ),
            ),
    );
  }

  void _openPlayer(BuildContext context) {
    final mp = Provider.of<MediaProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channel: channel,
          favoriteChannels: mp.favoriteChannels,
        ),
      ),
    );
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _remainText(AppLocalizations l, Programme current, DateTime now) {
    final remain = current.stop.difference(now).inMinutes;
    if (remain <= 0) return '';
    return l.remainMinutes(remain);
  }
}

/// 收藏心:实心=已收藏(品牌色),点击切换。
class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggle;

  const _FavoriteButton({required this.isFavorite, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? AppTokens.brand : AppTokens.textTertiary,
        size: 18,
      ),
    );
  }
}
