import 'package:flutter/material.dart';
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
        final mp = Provider.of<MediaProvider>(context, listen: false);
        await mp.fetchPlaylists();
        await mp.fetchFavoriteChannels();
        await mp.loadGridSizeLevel();
        await mp.loadAutoRefreshOnLaunch();
        await Provider.of<LocaleProvider>(context, listen: false).loadLocale();
        await loadRenderMode();
        await loadNativeEngineMode();
        await loadRecentModuleSetting();
        await loadFavoritesRowSetting();
        showToast(l.syncResult(res.playlistsAdded, res.favoritesAdded,
            res.settingsApplied));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showToast('${l.syncFailed}: $e');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Widget _section(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
        ...children,
      ],
    );
  }

  CheckboxListTile _check(String title, String? subtitle, bool value,
      ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.greenAccent,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(color: Colors.white54)),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = widget.bundle;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      appBar: AppBar(
        title: Text('${l.syncPreviewTitle} · ${b.deviceName}',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          _section(l.syncSecPlaylists, [
            for (final p in b.playlists)
              _check(p.name, p.url, _playlistUrls.contains(p.url), (v) {
                setState(() {
                  if (v == true) {
                    _playlistUrls.add(p.url);
                  } else {
                    _playlistUrls.remove(p.url);
                  }
                });
              }),
          ]),
          if (b.proxy != null)
            _section(l.updateProxy, [
              _check(b.proxy!.hostPort, null, _proxy,
                  (v) => setState(() => _proxy = v == true)),
            ]),
          _section(l.favorites, [
            for (final f in b.favorites)
              _check(f['name'] as String? ?? (f['id'] as String), null,
                  _favoriteIds.contains(f['id']), (v) {
                setState(() {
                  if (v == true) {
                    _favoriteIds.add(f['id'] as String);
                  } else {
                    _favoriteIds.remove(f['id'] as String);
                  }
                });
              }),
          ]),
          _section(l.syncSecSettings, [
            for (final k in b.settings.keys)
              _check(k, '${b.settings[k]}', _settingKeys.contains(k), (v) {
                setState(() {
                  if (v == true) {
                    _settingKeys.add(k);
                  } else {
                    _settingKeys.remove(k);
                  }
                });
              }),
          ]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _applying ? null : _apply,
              child: Text(l.syncApply),
            ),
          ),
        ],
      ),
    );
  }
}
