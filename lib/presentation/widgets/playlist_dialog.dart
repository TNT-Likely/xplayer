import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

typedef OnSuccessCallback = void Function(Playlist playlist);

class PlaylistDialog extends StatefulWidget {
  const PlaylistDialog({
    super.key,
    this.initialPlaylist,
    this.isNew = false,
    this.onSuccess,
  });
  final Playlist? initialPlaylist;
  final bool isNew;
  final OnSuccessCallback? onSuccess;
  @override
  State<PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<PlaylistDialog> {
  late final _name = TextEditingController(
    text: widget.initialPlaylist?.name ?? '',
  );
  late final _url = TextEditingController(
    text: widget.initialPlaylist?.url ?? '',
  );
  late final _epg = TextEditingController(
    text: widget.initialPlaylist?.epgUrl ?? '',
  );
  final _repository = PlaylistRepository();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _epg.dispose();
    super.dispose();
  }

  bool _http(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.host.isNotEmpty;
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim(),
        url = _url.text.trim(),
        epg = _epg.text.trim();
    final local = Uri.tryParse(url)?.scheme == 'file' || p.isAbsolute(url);
    if (name.isEmpty ||
        (!_http(url) && !local) ||
        (epg.isNotEmpty && !_http(epg))) {
      setState(
        () => _error = name.isEmpty
            ? '请填写列表名称。'
            : (!_http(url) && !local)
            ? '请输入有效的 http / https 地址，或选择本地 M3U 文件。'
            : '节目单地址需要使用 http 或 https。',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = await _repository.getAllPlaylists();
      if (existing.any(
        (p) => p.name.trim() == name && p.id != widget.initialPlaylist?.id,
      )) {
        throw StateError('已存在同名列表，请使用其他名称。');
      }
      final value = Playlist(
        id: widget.initialPlaylist?.id,
        name: name,
        url: url,
        epgUrl: epg,
        createdAt: widget.initialPlaylist?.createdAt,
        updatedAt: DateTime.now(),
      );
      final saved = widget.isNew
          ? await _repository.insertPlaylist(value)
          : await (() async {
              await _repository.updatePlaylist(value);
              return value;
            })();
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess?.call(saved);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError ? error.message : '保存失败，请重试。',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8'],
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final docs = await getApplicationDocumentsDirectory();
      final directory = Directory(p.join(docs.path, 'm3u'));
      await directory.create(recursive: true);
      final target = p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}_${p.basename(picked.name)}',
      );
      if (picked.path != null) {
        await File(picked.path!).copy(target);
      } else if (picked.bytes != null) {
        await File(target).writeAsBytes(picked.bytes!);
      } else {
        throw StateError('unreadable');
      }
      if (mounted) {
        setState(() {
          _url.text = Uri.file(target).toString();
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '无法读取文件，请重新选择。');
    }
  }

  Widget _field(Widget child) => Focus(
    skipTraversal: true,
    canRequestFocus: false,
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        FocusScope.of(context).nextFocus();
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        FocusScope.of(context).previousFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: child,
  );
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_saving,
      child: XpConfirmDialog(
        title: widget.isNew ? l.addPlaylist : l.editPlaylist,
        confirmLabel: widget.isNew ? l.add : l.save,
        loading: _saving,
        onConfirm: _save,
        onCancel: () => Navigator.of(context).pop(),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(
                XpTextField(
                  key: const Key('playlist-name'),
                  controller: _name,
                  label: l.name,
                  autofocus: true,
                  enabled: !_saving,
                ),
              ),
              const SizedBox(height: 16),
              _field(
                XpTextField(
                  key: const Key('playlist-url'),
                  controller: _url,
                  label: '列表地址',
                  hint: 'https://example.com/live.m3u',
                  keyboardType: TextInputType.url,
                  enabled: !_saving,
                ),
              ),
              const SizedBox(height: 12),
              XpButton(
                label: l.pickLocalM3u,
                icon: XpSymbol.sources,
                onPressed: _saving ? null : _pick,
                variant: XpButtonVariant.secondary,
              ),
              const SizedBox(height: 18),
              _field(
                XpTextField(
                  key: const Key('playlist-epg'),
                  controller: _epg,
                  label: '节目单地址（可选）',
                  hint: 'XMLTV / XMLTV.gz',
                  helper: '留空时会读取 M3U 文件头中的节目单地址。',
                  keyboardType: TextInputType.url,
                  enabled: !_saving,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: XpNotice(
                    title: '保存未完成',
                    description: _error!,
                    tone: XpTone.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
