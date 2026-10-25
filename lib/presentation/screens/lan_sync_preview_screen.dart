import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer_ui/xplayer_ui.dart';
import 'package:xplayer/shared/theme/theme_settings.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/locale_provider.dart';
import 'package:xplayer/services/sync/config_bundle.dart';
import 'package:xplayer/services/sync/sync_selection.dart';
import 'package:xplayer/services/sync/config_import_service.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer/utils/toast.dart';

/// 预览拉取到的配置,逐项勾选后应用到本机。
class LanSyncPreviewScreen extends StatefulWidget {
  final ConfigBundle bundle;
  const LanSyncPreviewScreen({super.key, required this.bundle});

  @override
  State<LanSyncPreviewScreen> createState() => _LanSyncPreviewScreenState();
}

class _LanSyncPreviewScreenState extends State<LanSyncPreviewScreen> {
  late final Set<String> _playlistUrls;
  late bool _proxy;
  late final Set<String> _favoriteIds;
  late final Set<String> _settingKeys;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    final b = widget.bundle;
    _playlistUrls = b.playlists.map((p) => p.url).toSet(); // 默认全选
    _proxy = b.proxy != null;
    _favoriteIds = b.favorites.map((f) => f['id'] as String).toSet();
    _settingKeys = b.settings.keys.toSet();
  }

  Future<void> _apply() async {
    final l = AppLocalizations.of(context)!;
    final mp = context.read<MediaProvider>();
    final locale = context.read<LocaleProvider>();
    final navigator = Navigator.of(context);
    if (_applying) return;
    setState(() => _applying = true);
    try {
      final res = await ConfigImportService().import(
        widget.bundle,
        SyncSelection(
          playlistUrls: _playlistUrls,
          proxy: _proxy,
          favoriteIds: _favoriteIds,
          settingKeys: _settingKeys,
        ),
      );
      // 热重载本机各状态,立即反映
      if (mounted) {
        await mp.fetchPlaylists();
        await mp.fetchFavoriteChannels();
        await mp.loadGridSizeLevel();
        await mp.loadAutoRefreshOnLaunch();
        await locale.loadLocale();
        await loadRenderMode();
        await loadNativeEngineMode();
        await loadRecentModuleSetting();
        await loadFavoritesRowSetting();
        await loadThemeColor();
        await mp.fetchChannels();
        await mp.loadCachedProgrammes();
        if (!mounted) return;
        showToast(
          l.syncResult(
            res.playlistsAdded,
            res.favoritesAdded,
            res.settingsApplied,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) showToast('${l.syncFailed}: $e');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<Map<String, Object>> _localValues() async {
    final media = context.read<MediaProvider>();
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final p in widget.bundle.playlists)
        'playlist:${p.url}': media.playlists.any((l) => l.url == p.url)
            ? '已存在'
            : '未添加',
      for (final f in widget.bundle.favorites)
        'favorite:${f['id']}':
            media.favoriteChannels.any((c) => c.id == f['id']) ? '已收藏' : '未收藏',
      for (final key in widget.bundle.settings.keys)
        'setting:$key': prefs.get(key)?.toString() ?? '默认值',
      'proxy': prefs.getString('update_proxy') ?? '未配置',
    };
  }

  late Future<Map<String, Object>> _local = _localValues();
  @override
  Widget build(BuildContext context) {
    final b = widget.bundle;
    final selection = <String>{
      for (final url in _playlistUrls) 'playlist:$url',
      for (final id in _favoriteIds) 'favorite:$id',
      for (final key in _settingKeys) 'setting:$key',
      if (_proxy) 'proxy',
    };
    return PopScope(
      canPop: !_applying,
      child: Scaffold(
        appBar: AppBar(title: Text('同步预览 · ${b.deviceName}')),
        body: FutureBuilder<Map<String, Object>>(
          future: _local,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return XpEmptyState(
                title: '读取本机配置失败',
                description: '当前没有写入任何同步变更。可以重试，或返回稍后处理。',
                actionLabel: '重新读取',
                onAction: () => setState(() => _local = _localValues()),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final local = snapshot.data!;
            final fields = [
              for (final p in b.playlists)
                XpSyncField(
                  id: 'playlist:${p.url}',
                  label: p.name,
                  local: '${local['playlist:${p.url}']}',
                  remote: p.url,
                ),
              for (final f in b.favorites)
                XpSyncField(
                  id: 'favorite:${f['id']}',
                  label: f['name'] as String? ?? '${f['id']}',
                  local: '${local['favorite:${f['id']}']}',
                  remote: '添加到收藏',
                ),
              if (b.proxy != null)
                XpSyncField(
                  id: 'proxy',
                  label: '网络代理',
                  local: '${local['proxy']}',
                  remote: b.proxy!.hostPort,
                ),
              for (final key in b.settings.keys)
                XpSyncField(
                  id: 'setting:$key',
                  label: key,
                  local: '${local['setting:$key']}',
                  remote: '${b.settings[key]}',
                ),
            ];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: XpSyncDiffPanel(
                fields: fields,
                selectedIds: selection,
                loading: _applying,
                onSelectionChanged: (ids) => setState(() {
                  _playlistUrls.clear();
                  _favoriteIds.clear();
                  _settingKeys.clear();
                  for (final id in ids) {
                    if (id.startsWith('playlist:')) {
                      _playlistUrls.add(id.substring(9));
                    }
                    if (id.startsWith('favorite:')) {
                      _favoriteIds.add(id.substring(9));
                    }
                    if (id.startsWith('setting:')) {
                      _settingKeys.add(id.substring(8));
                    }
                  }
                  _proxy = ids.contains('proxy');
                }),
                onApply: (_) => _apply(),
                onCancel: () => Navigator.pop(context),
              ),
            );
          },
        ),
      ),
    );
  }
}
