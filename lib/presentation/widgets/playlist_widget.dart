import 'package:flutter/material.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/utils/dialog.dart';
import 'package:xplayer/utils/toast.dart';
import '../../data/models/playlist_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlaylistListWidget extends StatelessWidget {
  final List<Playlist> playlists;
  final Function(int) onDelete;
  final Function(Playlist) onUpdate;
  final Function(int, String) onRefresh;
  final Function() onLoadAll;

  const PlaylistListWidget({
    super.key,
    required this.playlists,
    required this.onDelete,
    required this.onUpdate,
    required this.onRefresh,
    required this.onLoadAll,
  });

  void _showEditDialog(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlaylistDialog(
          isNew: false,
          initialPlaylist: playlist,
          onSuccess: (Playlist playlist) {
            showToast(AppLocalizations.of(context)!.updateSuccess);
            onLoadAll();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return ListTile(
          style: ListTileStyle.drawer,
          title: Text('${playlist.id}: ${playlist.name}',
              style: const TextStyle(color: Colors.white)),
          subtitle: Text(playlist.url,
              style: TextStyle(color: Colors.white.withOpacity(0.7))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              XIconButton(
                icon: Icons.edit,
                onPressed: () => _showEditDialog(context, playlist),
              ),
              const SizedBox(width: 8),
              XIconButton(
                onPressed: () => onRefresh(playlist.id!, playlist.url),
                icon: Icons.refresh,
              ),
              const SizedBox(width: 8),
              XIconButton(
                icon: Icons.delete,
                type: XIconButtonType.danger,
                onPressed: () => DialogUtils.showConfirmDialog(
                    context, () => onDelete(playlist.id!)),
              ),
            ],
          ),
        );
      },
    );
  }
}
