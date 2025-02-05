import 'package:flutter/material.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef OnSuccessCallback = void Function(Playlist playlist);

class PlaylistDialog extends StatelessWidget {
  final Playlist? initialPlaylist;
  final bool isNew;
  final OnSuccessCallback? onSuccess;

  const PlaylistDialog(
      {super.key, this.initialPlaylist, this.isNew = false, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    final PlaylistRepository repository = PlaylistRepository();
    final TextEditingController nameController = TextEditingController(
      text: initialPlaylist?.name ?? '',
    );
    final TextEditingController urlController = TextEditingController(
      text: initialPlaylist?.url ?? '',
    );

    Future<Playlist> addPlaylist(String name, String url) async {
      final newPlaylist = Playlist(name: name, url: url);
      return await repository.insertPlaylist(newPlaylist);
    }

    Future<Playlist> updatePlaylist(Playlist playlist) async {
      await repository.updatePlaylist(playlist);

      return playlist;
    }

    return AlertDialog(
      title: Text(
        isNew
            ? AppLocalizations.of(context)!.addPlaylist
            : AppLocalizations.of(context)!.editPlaylist,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.name,
                labelStyle: const TextStyle(color: Colors.white)),
            controller: nameController,
            autofocus: true,
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white),
          ),
          TextField(
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.url,
                labelStyle: const TextStyle(color: Colors.white)),
            controller: urlController,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      actions: [
        XTextButton(
          text: AppLocalizations.of(context)!.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        XTextButton(
          text: isNew
              ? AppLocalizations.of(context)!.add
              : AppLocalizations.of(context)!.save,
          type: XTextButtonType.primary,
          onPressed: () async {
            final newPlaylist = Playlist(
              id: initialPlaylist?.id ?? DateTime.now().millisecondsSinceEpoch,
              name: nameController.text.trim(),
              url: urlController.text.trim(),
            );

            late Playlist playlist;
            if (newPlaylist.name.isNotEmpty && newPlaylist.url.isNotEmpty) {
              try {
                if (isNew) {
                  playlist =
                      await addPlaylist(newPlaylist.name, newPlaylist.url);
                } else {
                  playlist = await updatePlaylist(newPlaylist);
                }
                Navigator.of(context).pop();
                if (onSuccess != null) {
                  onSuccess!(playlist);
                }
              } catch (error) {
                showToast(error.toString());
              }
            } else {
              showToast(AppLocalizations.of(context)!.nameAndUrlRequired);
            }
          },
        ),
      ],
    );
  }
}
