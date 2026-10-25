import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/adapters/app_actions.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

class PlaylistListScreen extends StatefulWidget {
  const PlaylistListScreen({super.key});
  @override
  State<PlaylistListScreen> createState() => _PlaylistListScreenState();
}

class _PlaylistListScreenState extends State<PlaylistListScreen> {
  final _counts = <int, int>{};
  final _busy = <int>{};
  final _errors = <int>{};
  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final media = context.read<MediaProvider>();
    final repository = PlaylistRepository();
    for (final list in media.playlists) {
      if (list.id == null) continue;
      final cache = await repository.getPlaylistChannels(list.id!);
      if (!mounted) return;
      setState(
        () => _counts[list.id!] = parseChannels(
          cache ?? '',
        ).map((c) => c.id.toLowerCase()).toSet().length,
      );
    }
  }

  Future<void> _refresh(Playlist playlist) async {
    final id = playlist.id!;
    if (_busy.contains(id)) return;
    setState(() {
      _busy.add(id);
      _errors.remove(id);
    });
    final media = context.read<MediaProvider>();
    try {
      await media.refreshPlaylistWithM3uById(id, playlist.url);
      await media.fetchPlaylists();
      if (media.currentPlaylistId == id) await media.fetchChannels();
      await _loadCounts();
      await media.refreshProgrammes();
    } catch (_) {
      if (mounted) setState(() => _errors.add(id));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _remove(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => XpConfirmDialog(
        title: '移除「${playlist.name}」？',
        confirmLabel: '确认移除',
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
        child: const Text('将移除这个列表及其频道缓存，已收藏的频道会保留。'),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<MediaProvider>().removePlaylist(playlist.id!);
    } catch (_) {
      showToast('移除失败，请重试');
    }
  }

  Future<void> _edit([Playlist? playlist]) async {
    await AppActions.editPlaylist(context, playlist: playlist);
    if (mounted) _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final media = context.watch<MediaProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.playlist),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: XpIconButton(
              icon: XpSymbol.plus,
              label: l.addPlaylist,
              onPressed: () => _edit(),
            ),
          ),
        ],
      ),
      body: media.playlists.isEmpty
          ? XpEmptyState(
              title: '添加第一个播放列表',
              description: '导入 M3U 地址或本地文件，开始整理你的频道。',
              icon: XpSymbol.sources,
              actionLabel: l.addPlaylist,
              onAction: () => _edit(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: media.playlists.length,
              itemBuilder: (context, i) {
                final playlist = media.playlists[i];
                final count = _counts[playlist.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: XpPlaylistCard(
                    name: playlist.name,
                    channelCount: count,
                    selected: playlist.id == media.currentPlaylistId,
                    status: _busy.contains(playlist.id)
                        ? XpPlaylistStatus.updating
                        : _errors.contains(playlist.id)
                        ? XpPlaylistStatus.error
                        : count == 0
                        ? XpPlaylistStatus.empty
                        : XpPlaylistStatus.ready,
                    updatedLabel: playlist.updatedAt == null
                        ? null
                        : xpDateTime(playlist.updatedAt!),
                    onSelect: () async {
                      final navigator = Navigator.of(context);
                      await media.updateCurrentPlaylist(playlist.id!);
                      if (mounted) navigator.pop();
                    },
                    onEdit: () => _edit(playlist),
                    onRemove: () => _remove(playlist),
                    onRetry: () => _refresh(playlist),
                    onRefresh: () => _refresh(playlist),
                  ),
                );
              },
            ),
    );
  }
}
