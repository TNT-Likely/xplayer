// 用于 jsonEncode

import 'package:flutter/material.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/models/channel_model.dart'; // 使用新的文件名
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/data/models/channel_test_result.dart';
import 'package:xplayer/data/models/iptv_presets.dart';
import 'package:xplayer/utils/channel_filter.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/data/repositories/favorites_repository.dart';
import 'package:xplayer/services/channel_test_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/extensions/m3u.dart';
import 'package:xplayer/utils/toast.dart'; // 导入 showToast
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MediaProvider with ChangeNotifier {
  final PlaylistRepository _playlistRepository = PlaylistRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  final ChannelTestService _testService = ChannelTestService();

  List<Playlist> _playlists = [];
  int _currentPlaylistId = -1;
  List<Channel> _channels = [];
  List<Channel> _favoriteChannels = [];
  List<Programme> _programmes = [];

  // 频道筛选状态(分组 + 搜索)
  String _searchQuery = '';
  String? _selectedGroup;

  // 首页频道项显示大小档位(0 最大 .. 4 最小,2=默认)
  int _gridSizeLevel = 2;

  // 测速后是否隐藏「无法播放」的频道(可恢复,持久化)
  bool _hideUnplayable = false;

  // 启动时是否自动联网更新频道/节目单(后台静默,不阻塞进入;持久化,默认开)
  bool _autoRefreshOnLaunch = true;

  // 频道测试相关
  Map<String, ChannelTestResult> _channelTestResults = {};
  bool _isTesting = false;
  int _testProgress = 0;
  int _testTotal = 0;

  // 初始化加载状态
  bool _isInitializing = true;

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

  /// 当前搜索关键字与选中分组。
  String get searchQuery => _searchQuery;
  String? get selectedGroup => _selectedGroup;

  /// 应用「搜索 + 分组」过滤后的频道(供网格展示)。
  /// 若已测速:可选隐藏「无法播放」的频道,并把「可播放」排到前面。
  List<Channel> get filteredChannels {
    var list =
        filterChannels(channels, query: _searchQuery, group: _selectedGroup);
    if (_channelTestResults.isEmpty) return list;

    if (_hideUnplayable) {
      list = list.where((c) {
        final r = _channelTestResults[c.id];
        // 仅隐藏明确失败/超时的;未测与成功的保留
        return r == null ||
            (r.status != TestStatus.failed && r.status != TestStatus.timeout);
      }).toList();
    }

    // 可播放优先:成功(按延迟升序) → 未测 → 失败/超时
    int rank(Channel c) {
      final r = _channelTestResults[c.id];
      if (r == null) return 1;
      if (r.status == TestStatus.success) return 0;
      return 2;
    }

    final sorted = [...list];
    sorted.sort((a, b) {
      final ra = rank(a), rb = rank(b);
      if (ra != rb) return ra - rb;
      final la = _channelTestResults[a.id]?.latency ?? 1 << 30;
      final lb = _channelTestResults[b.id]?.latency ?? 1 << 30;
      return la.compareTo(lb);
    });
    return sorted;
  }

  /// 是否已有测速结果(决定「隐藏无法播放」入口是否出现)。
  bool get hasTestResults => _channelTestResults.isNotEmpty;

  /// 是否隐藏无法播放的频道。
  bool get hideUnplayable => _hideUnplayable;

  /// 启动时是否自动更新(后台静默刷新)。
  bool get autoRefreshOnLaunch => _autoRefreshOnLaunch;

  /// 当前频道里去重的分组(供筛选 chips)。
  List<String> get availableGroups => distinctGroups(channels);

  /// 首页频道项显示大小档位(0..4)。
  int get gridSizeLevel => _gridSizeLevel;

  List<Channel> get favoriteChannels => _favoriteChannels;
  List<Programme> get programmes => _programmes;

  // 测试相关 getter
  Map<String, ChannelTestResult> get channelTestResults => _channelTestResults;
  bool get isTesting => _isTesting;
  int get testProgress => _testProgress;
  int get testTotal => _testTotal;
  String get testProgressText => '$_testProgress / $_testTotal';

  // 初始化状态 getter
  bool get isInitializing => _isInitializing;

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

  /// 按 URL 去重添加：已存在同 URL 的播放列表则直接返回(不重复创建)。
  /// 用于「推荐源」——重复点击或点已添加过的预置只会切换、不会产生重复项。
  Future<Playlist> addOrGetPlaylistByUrl(String name, String url) async {
    for (final p in _playlists) {
      if (p.url == url) return p;
    }
    final created = await _playlistRepository
        .insertPlaylist(Playlist(name: name, url: url));
    _playlists.add(created);
    notifyListeners();
    return created;
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
    _resetFilters(); // 切换播放列表时清空搜索/分组
    setState(newId);
    await fetchChannels(); // 切换播放单后立即刷新频道列表
    notifyListeners();
  }

  void setState(int newId) {
    _currentPlaylistId = newId;
    notifyListeners();
  }

  /// 设置搜索关键字。
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 设置选中分组(null/空 表示全部)。
  void setSelectedGroup(String? group) {
    _selectedGroup = group;
    notifyListeners();
  }

  /// 读取持久化的显示大小档位。
  Future<void> loadGridSizeLevel() async {
    final prefs = await SharedPreferences.getInstance();
    _gridSizeLevel = (prefs.getInt('grid_size_level') ?? 2).clamp(0, 4);
    notifyListeners();
  }

  /// 设置并持久化显示大小档位(0..4)。
  Future<void> setGridSizeLevel(int level) async {
    _gridSizeLevel = level.clamp(0, 4);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grid_size_level', _gridSizeLevel);
  }

  /// 读取持久化的「隐藏无法播放」开关。
  Future<void> loadHideUnplayable() async {
    final prefs = await SharedPreferences.getInstance();
    _hideUnplayable = prefs.getBool('hide_unplayable') ?? false;
    notifyListeners();
  }

  /// 设置并持久化「隐藏无法播放」开关。
  Future<void> setHideUnplayable(bool value) async {
    _hideUnplayable = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_unplayable', value);
  }

  /// 读取「启动时自动更新」开关(默认开)。
  Future<void> loadAutoRefreshOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _autoRefreshOnLaunch = prefs.getBool('auto_refresh_on_launch') ?? true;
    notifyListeners();
  }

  /// 设置并持久化「启动时自动更新」开关。
  Future<void> setAutoRefreshOnLaunch(bool value) async {
    _autoRefreshOnLaunch = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_refresh_on_launch', value);
  }

  void _resetFilters() {
    _searchQuery = '';
    _selectedGroup = null;
  }

  Future<void> loadLastSelectedPlaylistId() async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString('lastSelectedPlaylistId');

    if (lastId != null) {
      await updateCurrentPlaylist(int.parse(lastId));
    }
  }

  /// 初始化应用数据（用于启动屏）
  Future<void> initializeApp() async {
    try {
      _isInitializing = true;
      notifyListeners();

      // 加载播放列表
      await fetchPlaylists();

      // 加载显示大小偏好
      await loadGridSizeLevel();

      // 加载「隐藏无法播放」偏好
      await loadHideUnplayable();

      // 首启无任何源时,自动添加并选中默认预置源(iptv-org 中国;运行时拉取)
      await _maybeSeedDefaultPreset();

      // 加载「启动时自动更新」偏好
      await loadAutoRefreshOnLaunch();

      // 加载收藏频道
      await fetchFavoriteChannels();

      // 加载上次选择的播放列表(频道走缓存优先,启动快;不在此处阻塞联网)
      await loadLastSelectedPlaylistId();
    } catch (e) {
      print('[MediaProvider] 初始化失败: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }

    // 进入首页后,若开启「启动时自动更新」,后台静默刷新频道 + 节目单,
    // 不阻塞进入(修复每次启动都卡在联网更新导致很慢的问题)。
    if (_autoRefreshOnLaunch) {
      _refreshOnLaunchInBackground();
    }
  }

  /// 启动后台静默刷新:失败不打扰(已有本地缓存兜底)。
  Future<void> _refreshOnLaunchInBackground() async {
    try {
      await fetchChannels(forceRefresh: true, silent: true);
    } catch (_) {}
    try {
      await refreshProgrammes();
    } catch (_) {}
  }

  /// 首启无源时,自动添加并选中默认预置源(运行时拉取,不打包快照)。
  /// 用 shared_preferences 标记,用户删光源后不会被重新种入。
  Future<void> _maybeSeedDefaultPreset() async {
    if (_playlists.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seeded_default_preset') ?? false) return;
    try {
      final created = await _playlistRepository.insertPlaylist(
        Playlist(name: kDefaultPreset.fallbackName, url: kDefaultPreset.url),
      );
      _playlists.add(created);
      await prefs.setBool('seeded_default_preset', true);
      final id = created.id;
      if (id != null) {
        await prefs.setString('lastSelectedPlaylistId', id.toString());
        _currentPlaylistId = id;
      }
    } catch (e) {
      print('[MediaProvider] 预置源种入失败: $e');
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

  /// 加载当前播放列表的频道。
  /// - 默认「缓存优先」:有本地缓存就直接用,不联网(启动/切换都很快);
  /// - [forceRefresh]=true 才联网重拉并写回缓存(手动刷新 / 后台自动更新);
  /// - [silent]=true 时联网失败不弹 toast(后台刷新用)。
  Future<void> fetchChannels(
      {bool forceRefresh = false, bool silent = false}) async {
    if (_currentPlaylistId == -1) {
      _channels = _favoriteChannels; // 使用收藏频道
      notifyListeners();
      return;
    }

    final playlist =
        await _playlistRepository.getPlaylistById(_currentPlaylistId);
    if (playlist == null) {
      _channels = [];
      notifyListeners();
      return;
    }

    // 缓存优先:避免每次启动/切换都联网重拉(慢)
    if (!forceRefresh) {
      final cached =
          await _playlistRepository.getPlaylistChannels(_currentPlaylistId);
      if (cached != null && cached.isNotEmpty) {
        _channels = parseChannels(cached);
        notifyListeners();
        return;
      }
    }

    // 强制刷新,或本地无缓存:联网拉取并写回缓存
    try {
      final updatedChannels = await _playlistRepository
          .updatePlaylistWithM3uById(_currentPlaylistId, playlist.url);
      _channels = updatedChannels.toChannels();
    } catch (error) {
      if (!silent) showToast(error.toString());
      // Fallback: 从文件存储读取已保存的channels
      final channelsJson =
          await _playlistRepository.getPlaylistChannels(_currentPlaylistId);
      _channels = parseChannels(channelsJson ?? '');
    }
    notifyListeners();
  }

  Future<void> refreshChannels() async {
    await fetchChannels(forceRefresh: true);
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

  /// 测试所有频道
  Future<void> testAllChannels() async {
    if (_isTesting) return; // 防止重复测试

    _isTesting = true;
    _testProgress = 0;
    _testTotal = _channels.length;
    _channelTestResults.clear();
    notifyListeners();

    try {
      await _testService.testChannelsBatch(
        _channels,
        onProgress: (current, total, channelId, result) {
          _testProgress = current;
          _channelTestResults[channelId] = result;
          notifyListeners();
        },
      );
    } finally {
      _isTesting = false;
      notifyListeners();
    }
  }

  /// 取消测试
  void cancelTest() {
    if (_isTesting) {
      _testService.cancelTest();
      _isTesting = false;
      notifyListeners();
    }
  }

  /// 获取频道的测试结果
  ChannelTestResult? getChannelTestResult(String channelId) {
    return _channelTestResults[channelId];
  }

  /// 清除测试结果
  void clearTestResults() {
    _channelTestResults.clear();
    _testProgress = 0;
    _testTotal = 0;
    notifyListeners();
  }
}
