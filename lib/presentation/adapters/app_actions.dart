import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/utils/toast.dart';

/// 页面和组件共享的宿主动作；组件包不感知 Provider、导航或持久化。
abstract final class AppActions {
  static Future<void> play(BuildContext context, Channel channel) async {
    if (channel.source.isEmpty) {
      showToast('这个频道没有可用的播放地址');
      return;
    }
    final media = context.read<MediaProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channel: channel,
          favoriteChannels: media.favoriteChannels,
        ),
      ),
    );
  }

  static Future<void> favorite(BuildContext context, Channel channel) async {
    try {
      await context.read<MediaProvider>().toggleFavorite(channel);
    } catch (_) {
      showToast('收藏未保存，请重试');
    }
  }

  static Future<void> editPlaylist(
    BuildContext context, {
    Playlist? playlist,
  }) async {
    final media = context.read<MediaProvider>();
    Playlist? saved;
    await showDialog<void>(
      context: context,
      builder: (_) => PlaylistDialog(
        isNew: playlist == null,
        initialPlaylist: playlist,
        onSuccess: (p) => saved = p,
      ),
    );
    if (saved == null) return;
    try {
      await media.fetchPlaylists();
      if (playlist == null || saved!.id == media.currentPlaylistId) {
        await media.updateCurrentPlaylist(saved!.id!);
      }
      await media.refreshProgrammes();
    } catch (_) {
      showToast('列表已保存，加载失败时可在列表页重试');
    }
  }
}
