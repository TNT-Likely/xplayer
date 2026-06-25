import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/data/repositories/favorites_repository.dart';
import 'package:xplayer/services/update/update_proxy.dart';
import 'package:xplayer/services/sync/config_bundle.dart';
import 'package:xplayer/services/sync/sync_device.dart';

/// 汇总本机配置为 ConfigBundle(供源端 /config 返回)。
class ConfigExportService {
  Future<ConfigBundle> export() async {
    final prefs = await SharedPreferences.getInstance();

    final playlists = (await PlaylistRepository().getAllPlaylists())
        .map((p) => SyncPlaylist(name: p.name, url: p.url, epgUrl: p.epgUrl))
        .toList();

    SyncProxy? proxy;
    final hostPort = await UpdateProxy.get();
    if (hostPort != null && hostPort.isNotEmpty) {
      proxy = SyncProxy(
        hostPort: hostPort,
        useForUpdate: await UpdateProxy.getUseForUpdate(),
        useForSource: await UpdateProxy.getUseForSource(),
      );
    }

    final favorites = (await FavoritesRepository().getAllFavorites())
        .map((c) => <String, dynamic>{
              'id': c.id,
              'name': c.name,
              'logo': c.logo,
              'source': jsonEncode(c.source.map((s) => s.toJson()).toList()),
            })
        .toList();

    final settings = <String, dynamic>{
      'player_use_surface_view': prefs.getBool('player_use_surface_view'),
      'player_use_native_engine': prefs.getBool('player_use_native_engine'),
      'home_show_recent': prefs.getBool('home_show_recent'),
      'home_show_favorites_row': prefs.getBool('home_show_favorites_row'),
      'grid_size_level': prefs.getInt('grid_size_level'),
      'language_code': prefs.getString('language_code'),
      'auto_refresh_channels': prefs.getBool('auto_refresh_channels'),
      'auto_refresh_programmes': prefs.getBool('auto_refresh_programmes'),
    }..removeWhere((_, v) => v == null);

    return ConfigBundle(
      deviceName: await syncDeviceName(),
      playlists: playlists,
      proxy: proxy,
      favorites: favorites,
      settings: settings,
    );
  }
}
