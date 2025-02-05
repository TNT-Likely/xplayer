// 用于 jsonEncode

import 'package:flutter/material.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/models/channel_model.dart'; // 使用新的文件名
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/data/repositories/favorites_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/extensions/m3u.dart';
import 'package:xplayer/utils/toast.dart'; // 导入 showToast
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MediaProvider with ChangeNotifier {
  final PlaylistRepository _playlistRepository = PlaylistRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();

  List<Playlist> _playlists = [];
  int _currentPlaylistId = -1;
  List<Channel> _channels = [];
  List<Channel> _favoriteChannels = [];
  List<Programme> _programmes = [];

// 使用 late 关键字延迟初始化 localizations
  late AppLocalizations _localizations;

  List<Playlist> get playlists => _playlists;
  int get currentPlaylistId => _currentPlaylistId;

  Playlist get currentPlaylist {
    try {
      return _playlists
          .firstWhere((element) => element.id == _currentPlaylistId);
    } catch (error) {
      return Playlist(name: _localizations.favorites, url: '', id: -1);
    }
  }

  List<Channel> get channels => _mergeChannels(_channels);
  List<Channel> get favoriteChannels => _favoriteChannels;
  List<Programme> get programmes => _programmes;

  void setLocalizations(AppLocalizations localizations) {
    _localizations = localizations;
  }

  Future<void> initialize() async {
    await fetchPlaylists();
    await fetchFavoriteChannels();
    await loadLastSelectedPlaylistId();
    await refreshProgrammes();
  }

  Future<void> fetchPlaylists() async {
    final storePlaylists = await _playlistRepository.getAllPlaylists();
    _playlists = [...storePlaylists];
    notifyListeners();
  }

  Future<void> addPlaylist(String name, String url) async {
    final newPlaylist = await _playlistRepository
        .insertPlaylist(Playlist(name: name, url: url)); // 使用 insertPlaylist
    _playlists.add(newPlaylist);
    notifyListeners();
  }

  Future<void> removePlaylist(int id) async {
    await _playlistRepository.deletePlaylist(id); // 使用 deletePlaylist
    _playlists.removeWhere((playlist) => playlist.id == id);
    notifyListeners();
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await _playlistRepository.updatePlaylist(playlist);
    notifyListeners();
  }

  Future<void> updateCurrentPlaylist(int newId) async {
    setState(newId);
    await fetchChannels(); // 切换播放单后立即刷新频道列表
    notifyListeners();
  }

  void setState(int newId) {
    _currentPlaylistId = newId;
    notifyListeners();
  }

  Future<void> loadLastSelectedPlaylistId() async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString('lastSelectedPlaylistId');

    if (lastId != null) {
      await updateCurrentPlaylist(int.parse(lastId));
    }
  }

  // 检查频道是否已收藏
  bool _isFavorite(Channel channel) {
    return _favoriteChannels.any((fav) => fav.id == channel.id);
  }

  List<Channel> _mergeChannels(List<Channel> channels) {
    final Map<String, Channel> mergedChannels = {};

    for (final channel in channels) {
      final String lowerCaseId = channel.id.toLowerCase();

      if (!mergedChannels.containsKey(lowerCaseId)) {
        // 如果还没有添加过此 ID，则直接加入 map 中
        mergedChannels[lowerCaseId] = channel;
      } else {
        // 如果已经存在相同 ID 的 channel，则合并 source 列表
        final existingChannel = mergedChannels[lowerCaseId];
        if (existingChannel != null &&
            !existingChannel.source
                .any((element) => element.link == channel.source.first.link)) {
          existingChannel.source.addAll(channel.source);
        }
      }
    }

    // 返回合并后的频道列表
    return mergedChannels.values.toList();
  }

  // 排序方法，默认按是否已收藏和收藏顺序排序
  List<Channel> _sortChannels(List<Channel> channels) {
    // 创建副本以避免修改原始列表
    var sortedChannels = List<Channel>.from(channels);

    // 按照是否已收藏和收藏顺序排序
    sortedChannels.sort((a, b) {
      bool isAFavorite = _isFavorite(a);
      bool isBFavorite = _isFavorite(b);

      if (isAFavorite && !isBFavorite) return -1; // a 在前
      if (!isAFavorite && isBFavorite) return 1; // b 在前
      if (isAFavorite && isBFavorite) {
        // 如果两个都是收藏的，根据它们在 favoriteChannels 中的 createdAt 时间排序
        DateTime? createdAtA = _getCreatedAtFromFavorites(a);
        DateTime? createdAtB = _getCreatedAtFromFavorites(b);

        if (createdAtA == null && createdAtB == null) return 0;
        if (createdAtA == null) return 1; // a 在后
        if (createdAtB == null) return -1; // b 在后

        // 根据创建时间排序（最近创建的在前）
        return createdAtB.compareTo(createdAtA);
      }
      return 0; // 都不是收藏的，保持原有顺序
    });

    return sortedChannels;
  }

  DateTime? _getCreatedAtFromFavorites(Channel channel) {
    // 假设 _favoriteChannels 是一个包含所有收藏频道的列表
    final favorite =
        _favoriteChannels.firstWhere((fav) => fav.id == channel.id);
    return favorite.createdAt;
  }

  Future<void> fetchFavoriteChannels() async {
    final favoriteChannels = await _favoritesRepository.getAllFavorites();
    _favoriteChannels = favoriteChannels;
    notifyListeners();
  }

  Future<void> refreshPlaylistWithM3uById(int id, String url) async {
    await _playlistRepository.updatePlaylistWithM3uById(id, url);
  }

  Future<void> refreshProgrammes() async {
    _programmes = await _playlistRepository.fetchAllPlaylistsProgrammes();
    notifyListeners();
  }

  Future<void> fetchChannels() async {
    if (_currentPlaylistId == -1) {
      _channels = _favoriteChannels; // 使用收藏频道
    } else {
      final playlist =
          await _playlistRepository.getPlaylistById(_currentPlaylistId);
      if (playlist == null) {
        _channels = [];
      } else {
        try {
          final updatedChannels = await _playlistRepository
              .updatePlaylistWithM3uById(_currentPlaylistId, playlist.url);
          _channels = updatedChannels.toChannels();
        } catch (error) {
          showToast(error.toString()); // 使用正确的导入
          _channels = parseChannels(playlist.channels ?? '');
        }
      }
    }
    notifyListeners();
  }

  Future<void> refreshChannels() async {
    await fetchChannels();
  }

  Future<void> toggleFavorite(Channel channel) async {
    if (_favoriteChannels.any((fav) => fav.id == channel.id)) {
      // 使用 id 来判断
      await _favoritesRepository.removeFavorite(channel.id);
      _favoriteChannels.removeWhere((fav) => fav.id == channel.id);
    } else {
      await _favoritesRepository.addFavorite(channel);
      _favoriteChannels.add(channel);
    }
    notifyListeners();
  }

  Future<bool> isFavorite(Channel channel) async {
    final isFavorite = await _favoritesRepository.isFavorite(channel.id);

    return isFavorite;
  }

  Future<void> addFavorite(Channel channel) async {
    await _favoritesRepository.addFavorite(channel);
    _favoriteChannels.add(channel);
    notifyListeners();
  }

  Future<void> removeFavorite(Channel channel) async {
    await _favoritesRepository.removeFavorite(channel.id);
    _favoriteChannels.removeWhere((element) => element.id == channel.id);
    notifyListeners();
  }
}
