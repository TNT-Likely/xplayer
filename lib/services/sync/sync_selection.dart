import 'package:xplayer/services/sync/config_bundle.dart';

/// 用户在预览页的勾选。各类别按"标识集合"决定应用哪些。
class SyncSelection {
  final Set<String> playlistUrls;
  final bool proxy;
  final Set<String> favoriteIds;
  final Set<String> settingKeys;
  const SyncSelection({
    this.playlistUrls = const {},
    this.proxy = false,
    this.favoriteIds = const {},
    this.settingKeys = const {},
  });
}

List<SyncPlaylist> selectedPlaylists(ConfigBundle b, SyncSelection s) =>
    b.playlists.where((p) => s.playlistUrls.contains(p.url)).toList();

/// 过滤掉本机已有(同 url)的播放列表。
List<SyncPlaylist> playlistsToAdd(List<SyncPlaylist> picked,
        {required Set<String> existingUrls}) =>
    picked.where((p) => !existingUrls.contains(p.url)).toList();

/// 过滤掉本机已有(同 id)的收藏。
List<Map<String, dynamic>> favoritesToAdd(List<Map<String, dynamic>> picked,
        {required Set<String> existingIds}) =>
    picked.where((f) => !existingIds.contains(f['id'])).toList();
