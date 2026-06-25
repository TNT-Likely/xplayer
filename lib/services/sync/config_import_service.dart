import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/data/repositories/favorites_repository.dart';
import 'package:xplayer/services/update/update_proxy.dart';
import 'package:xplayer/services/sync/config_bundle.dart';
import 'package:xplayer/services/sync/sync_selection.dart';

class ImportResult {
  final int playlistsAdded, playlistsSkipped, favoritesAdded, favoritesSkipped;
  final bool proxyApplied;
  final int settingsApplied;
  const ImportResult(this.playlistsAdded, this.playlistsSkipped,
      this.favoritesAdded, this.favoritesSkipped, this.proxyApplied,
      this.settingsApplied);
}

/// 把(按勾选过滤的)ConfigBundle 应用到本机。播放列表/收藏合并去重;代理/设置覆盖。
class ConfigImportService {
  Future<ImportResult> import(ConfigBundle b, SyncSelection sel) async {
    final repo = PlaylistRepository();
    final favRepo = FavoritesRepository();
    final prefs = await SharedPreferences.getInstance();

    // 播放列表(同 url 跳过;插入后补 epgUrl)
    final picked = selectedPlaylists(b, sel);
    final existingUrls =
        (await repo.getAllPlaylists()).map((p) => p.url).toSet();
    final toAdd = playlistsToAdd(picked, existingUrls: existingUrls);
    for (final p in toAdd) {
      final inserted = await repo.insertPlaylist(Playlist(name: p.name, url: p.url));
      if (p.epgUrl != null && p.epgUrl!.isNotEmpty) {
        await repo.updatePlaylist(Playlist(
            id: inserted.id, name: p.name, url: p.url, epgUrl: p.epgUrl));
      }
    }
    final plAdded = toAdd.length;
    final plSkipped = picked.length - toAdd.length;

    // 代理(覆盖)
    bool proxyApplied = false;
    if (sel.proxy && b.proxy != null) {
      await UpdateProxy.set(b.proxy!.hostPort);
      await UpdateProxy.setUseForUpdate(b.proxy!.useForUpdate);
      await UpdateProxy.setUseForSource(b.proxy!.useForSource);
      proxyApplied = true;
    }

    // 收藏(同 id 跳过)
    final pickedFavs =
        b.favorites.where((f) => sel.favoriteIds.contains(f['id'])).toList();
    final existingFavIds =
        (await favRepo.getAllFavorites()).map((c) => c.id).toSet();
    final favToAdd = favoritesToAdd(pickedFavs, existingIds: existingFavIds);
    for (final f in favToAdd) {
      final sources = List.from(jsonDecode(f['source'] as String? ?? '[]'))
          .map((e) => Source.fromJson(e))
          .toList();
      await favRepo.addFavorite(Channel(
          id: f['id'] as String,
          name: f['name'] as String? ?? '',
          logo: f['logo'] as String?,
          source: sources));
    }
    final favAdded = favToAdd.length;
    final favSkipped = pickedFavs.length - favToAdd.length;

    // 设置(逐键覆盖,仅勾选)
    int settingsApplied = 0;
    for (final k in sel.settingKeys) {
      if (!b.settings.containsKey(k)) continue;
      final v = b.settings[k];
      if (v is bool) {
        await prefs.setBool(k, v);
      } else if (v is int) {
        await prefs.setInt(k, v);
      } else if (v is String) {
        await prefs.setString(k, v);
      } else {
        continue;
      }
      settingsApplied++;
    }

    return ImportResult(
        plAdded, plSkipped, favAdded, favSkipped, proxyApplied, settingsApplied);
  }
}
