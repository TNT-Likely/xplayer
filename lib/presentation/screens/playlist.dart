import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/presentation/widgets/bg_wrapper.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:xplayer/presentation/widgets/playlist_widget.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlaylistListScreen extends StatelessWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BgWrapper(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: XIconButton(
          icon: Icons.arrow_back_ios_rounded,
          hoverBgOnly: true,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(localizations.playlist,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0, // 移除阴影以保持完全透明效果
        iconTheme: const IconThemeData(color: Colors.white), // 设置图标颜色为白色
        actions: [
          XIconButton(
            tooltipMessage: localizations.addPlaylistTooltip,
            icon: Icons.add, // 使用白色图标按钮
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, mediaProvider, _) {
          return PlaylistListWidget(
            playlists: mediaProvider.playlists,
            onDelete: (id) async {
              await mediaProvider.removePlaylist(id);
              showToast(localizations.deleteSuccess);
            },
            onUpdate: (playlist) async {
              await mediaProvider.updatePlaylist(playlist);
              showToast(localizations.updateSuccess);
            },
            onLoadAll: () async {
              await mediaProvider.fetchPlaylists();
            },
            onRefresh: (id, url) async {
              try {
                await mediaProvider.refreshPlaylistWithM3uById(id, url);
                showToast(localizations.refreshSuccess);
              } catch (error) {
                showToast(localizations.refreshFailed(error.toString()));
              }
            },
          );
        },
      ),
    ));
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlaylistDialog(
          isNew: true,
          onSuccess: (Playlist playlist) async {
            final mediaProvider =
                Provider.of<MediaProvider>(context, listen: false);
            await mediaProvider.fetchPlaylists(); // 加载最新的播放列表
          },
        );
      },
    );
  }
}
