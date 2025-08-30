import 'package:flutter/material.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';

typedef OnSuccessCallback = void Function(Playlist playlist);

class PlaylistDialog extends StatefulWidget {
  final Playlist? initialPlaylist;
  final bool isNew;
  final OnSuccessCallback? onSuccess;

  const PlaylistDialog(
      {Key? key, this.initialPlaylist, this.isNew = false, this.onSuccess})
      : super(key: key);

  @override
  State<PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<PlaylistDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;

  late final FocusNode _nameFocus;
  late final FocusNode _urlFocus;
  late final FocusNode _cancelFocus;
  late final FocusNode _okFocus;
  late final FocusNode _listenerFocus;

  final _nameOrder = const NumericFocusOrder(1.0);
  final _urlOrder = const NumericFocusOrder(2.0);
  final _cancelOrder = const NumericFocusOrder(3.0);
  final _okOrder = const NumericFocusOrder(4.0);

  final PlaylistRepository _repository = PlaylistRepository();

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialPlaylist?.name ?? '');
    _urlController =
        TextEditingController(text: widget.initialPlaylist?.url ?? '');

    _nameFocus = FocusNode();
    _urlFocus = FocusNode();
    _cancelFocus = FocusNode();
    _okFocus = FocusNode();
    _listenerFocus = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _listenerFocus.requestFocus();
        _nameFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _nameFocus.dispose();
    _urlFocus.dispose();
    _cancelFocus.dispose();
    _okFocus.dispose();
    _listenerFocus.dispose();
    super.dispose();
  }

  Future<Playlist> _addPlaylist(String name, String url) async {
    final newPlaylist = Playlist(name: name, url: url);
    return await _repository.insertPlaylist(newPlaylist);
  }

  Future<Playlist> _updatePlaylist(Playlist playlist) async {
    await _repository.updatePlaylist(playlist);
    return playlist;
  }

  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    final key = event.logicalKey;
    final primary = FocusManager.instance.primaryFocus;

    if (key == LogicalKeyboardKey.arrowDown) {
      if (primary == _nameFocus) {
        _urlFocus.requestFocus();
      } else if (primary == _urlFocus) {
        _cancelFocus.requestFocus();
      } else if (primary == _cancelFocus) {
        _okFocus.requestFocus();
      }
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (primary == _okFocus) {
        _cancelFocus.requestFocus();
      } else if (primary == _cancelFocus) {
        _urlFocus.requestFocus();
      } else if (primary == _urlFocus) {
        _nameFocus.requestFocus();
      }
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select) {
      if (primary == _okFocus) {
        _onSubmit();
      } else if (primary == _cancelFocus) {
        Navigator.of(context).pop();
      }
    }
  }

  void _onSubmit() async {
    final newPlaylist = Playlist(
      id: widget.initialPlaylist?.id ?? DateTime.now().millisecondsSinceEpoch,
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
    );

    if (newPlaylist.name.isEmpty || newPlaylist.url.isEmpty) {
      showToast(AppLocalizations.of(context)!.nameAndUrlRequired);
      return;
    }

    try {
      Playlist playlist;
      if (widget.isNew) {
        playlist = await _addPlaylist(newPlaylist.name, newPlaylist.url);
      } else {
        playlist = await _updatePlaylist(newPlaylist);
      }
      Navigator.of(context).pop();
      widget.onSuccess?.call(playlist);
    } catch (e) {
      showToast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _listenerFocus,
      onKey: _handleKey,
      child: AlertDialog(
        title: Text(
          widget.isNew
              ? AppLocalizations.of(context)!.addPlaylist
              : AppLocalizations.of(context)!.editPlaylist,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
        content: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FocusTraversalOrder(
                order: _nameOrder,
                child: Focus(
                  onKey: (node, event) {
                    if (event is RawKeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      _urlFocus.requestFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    focusNode: _nameFocus,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.name,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    controller: _nameController,
                    autofocus: true,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    enableInteractiveSelection: false,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => _urlFocus.requestFocus(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FocusTraversalOrder(
                order: _urlOrder,
                child: Focus(
                  onKey: (node, event) {
                    if (event is RawKeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _cancelFocus.requestFocus();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowUp) {
                        _nameFocus.requestFocus();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    focusNode: _urlFocus,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.url,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    enableInteractiveSelection: false,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () => _cancelFocus.requestFocus(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FocusTraversalOrder(
            order: _cancelOrder,
            child: XTextButton(
              focusNode: _cancelFocus,
              text: AppLocalizations.of(context)!.cancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          FocusTraversalOrder(
            order: _okOrder,
            child: XTextButton(
              focusNode: _okFocus,
              text: widget.isNew
                  ? AppLocalizations.of(context)!.add
                  : AppLocalizations.of(context)!.save,
              type: XTextButtonType.primary,
              onPressed: _onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
