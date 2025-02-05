import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/utils/dialog.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChannelActions {
  static Future<void> handleMoreAction(BuildContext context, Channel channel,
      VoidCallback? onChannelUpdated) async {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    bool isFavorited = mediaProvider.favoriteChannels.any(
      (element) => element.id == channel.id,
    );

    DialogUtils.showActionsDialog(context,
        children: [
          XTextButton(
            text: isFavorited
                ? AppLocalizations.of(context)!.favorites
                : AppLocalizations.of(context)!.favorite,
            width: 150,
            onPressed: () async {
              await toggleFavorite(
                  mediaProvider, channel, context, onChannelUpdated);
              Navigator.of(context).pop();
            },
          )
        ],
        title: null,
        cancelButtonText: '');
  }

  static Future<void> toggleFavorite(
      MediaProvider mediaProvider,
      Channel channel,
      BuildContext context,
      VoidCallback? onChannelUpdated) async {
    try {
      if (await mediaProvider.isFavorite(channel)) {
        await mediaProvider.removeFavorite(channel);
        showToast(AppLocalizations.of(context)!.removedFromFavorites);
      } else {
        await mediaProvider.addFavorite(channel);
        showToast(AppLocalizations.of(context)!.addedToFavorites);
      }

      if (onChannelUpdated != null) {
        onChannelUpdated();
      }
    } catch (e) {
      showToast(AppLocalizations.of(context)!.operationFailed(e.toString()));
    }
  }
}
